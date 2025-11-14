# frozen_string_literal: true

# SortableController
#
# ソート機能の共通化を提供するConcern
#
# 使用例:
#   class ProductsController < ApplicationController
#     include SortableController
#
#     define_sort_options(
#       display_order: -> { ordered },
#       created_at: -> { order(created_at: :desc) },
#       name: -> { order(:name) },
#       category: -> { joins(:category).order('categories.name', :name) },
#       updated_at: -> { order(updated_at: :desc) }
#     )
#
#     def index
#       sorted_index(Resources::Product, default: 'display_order')
#     end
#   end
#
# 機能:
#   - クラスレベルでソートオプションを定義
#   - 共通の apply_sort メソッドを提供
#   - sorted_index メソッドでindex アクションの定型コードを省略
#   - SearchableController と連携可能
module SortableController
  extend ActiveSupport::Concern

  included do
    # ソートオプションの定義をクラス属性として保持
    class_attribute :sort_option_definitions, default: {}
  end

  module ClassMethods
    # ソートオプションを定義
    #
    # @param options [Hash<Symbol, Proc>] ソートキーとクエリ生成Procのマップ
    # @return [void]
    #
    # @example
    #   define_sort_options(
    #     display_order: -> { ordered },
    #     name: -> { order(:name) },
    #     category: -> { joins(:category).order('categories.name', :name) }
    #   )
    def define_sort_options(options)
      self.sort_option_definitions = options
    end
  end

  # ソート付き index アクションの共通実装
  #
  # @param model_class [Class] モデルクラス（例: Resources::Product）
  # @param default [String, Symbol] デフォルトのソートキー
  # @param scope [Symbol] 使用する scope（デフォルト: :for_index）
  # @param includes [Array, Symbol] eager loading する関連（デフォルト: なし）
  # @param ivar_name [Symbol] インスタンス変数名（デフォルト: モデル名の複数形）
  # @return [void]
  #
  # @example
  #   def index
  #     sorted_index(Resources::Product, default: 'display_order')
  #   end
  #
  # @example カスタムインクルード
  #   def index
  #     sorted_index(
  #       Resources::Material,
  #       default: 'display_order',
  #       includes: [:category, :unit_for_product, :order_group]
  #     )
  #   end
  def sorted_index(model_class, default:, scope: :for_index, includes: nil, ivar_name: nil)
    # インスタンス変数名を自動決定（例: Resources::Product -> @products）
    ivar_name ||= "@#{model_class.name.demodulize.underscore.pluralize}"

    # ベースクエリ構築
    base_query = if model_class.respond_to?(scope)
                   model_class.public_send(scope)
                 else
                   model_class.all
                 end

    # eager loading
    base_query = base_query.includes(includes) if includes.present?

    # 検索・フィルタ適用
    base_query = base_query.search_and_filter(search_params) if respond_to?(:search_params, true)

    # ソート適用
    sorted_query = apply_sort(base_query, default: default)

    # ページネーション適用
    paginated_query = apply_pagination(sorted_query)

    # インスタンス変数に設定
    instance_variable_set(ivar_name, paginated_query)

    # 検索語を設定
    set_search_term_for_view if respond_to?(:set_search_term_for_view, true)
  end

  private

  # ソートを適用する共通メソッド
  #
  # @param base_query [ActiveRecord::Relation] ソート対象のクエリ
  # @param default [String, Symbol] デフォルトのソートキー（省略時は最初に定義されたもの）
  # @return [ActiveRecord::Relation] ソート済みのクエリ
  #
  # @example
  #   @products = apply_sort(
  #     Product.search_and_filter(search_params),
  #     default: 'display_order'
  #   )
  def apply_sort(base_query, default: nil)
    sort_by = params[:sort_by]&.to_sym || default&.to_sym || sort_option_definitions.keys.first

    sort_proc = sort_option_definitions[sort_by]

    if sort_proc
      base_query.instance_exec(&sort_proc)
    else
      # 定義されていないソートキーの場合はデフォルトを使用
      default_key = default&.to_sym || sort_option_definitions.keys.first
      default_proc = sort_option_definitions[default_key]
      base_query.instance_exec(&default_proc)
    end
  end
end
