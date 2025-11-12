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
#       @products = apply_sort(
#         Product.search_and_filter(search_params),
#         default: 'display_order'
#       )
#     end
#   end
#
# 機能:
#   - クラスレベルでソートオプションを定義
#   - 共通の apply_sort メソッドを提供
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
