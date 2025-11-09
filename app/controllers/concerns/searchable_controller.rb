# frozen_string_literal: true

# SearchableController
#
# 検索パラメータの定義と共通化を提供するConcern
#
# 使用例:
#   class ProductsController < ApplicationController
#     include SearchAndFilterConcern
#     include SearchableController
#
#     define_search_params :name, :category_id, :status
#
#     def index
#       @products = Product.search_and_filter(search_params)
#     end
#   end
#
# 機能:
#   - クラスレベルで検索パラメータを定義
#   - 共通の search_params メソッドを提供
#   - SearchAndFilterConcernと連携
module SearchableController
  extend ActiveSupport::Concern

  included do
    # 許可する検索キーの配列をクラス属性として定義
    class_attribute :search_params_keys, default: []
  end

  module ClassMethods
    # 検索パラメータのキーを定義
    #
    # @param keys [Array<Symbol>] 許可する検索パラメータキー
    # @return [void]
    #
    # @example
    #   define_search_params :name, :category_id, :status
    def define_search_params(*keys)
      self.search_params_keys = keys
    end
  end

  private

  # 共通の検索パラメータメソッド
  #
  # define_search_params で定義されたキーを使用して、
  # get_and_normalize_search_params を呼び出す
  #
  # @return [Hash] 正規化された検索パラメータ
  def search_params
    get_and_normalize_search_params(*search_params_keys)
  end
end
