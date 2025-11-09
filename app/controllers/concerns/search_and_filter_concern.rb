# frozen_string_literal: true

# SearchAndFilterConcern
#
# 検索パラメータの取得と正規化を提供するConcern
#
# 使用例:
#   class ProductsController < ApplicationController
#     include SearchAndFilterConcern
#
#     def index
#       search_params = get_and_normalize_search_params(:name, :category_id)
#       @products = Product.search_and_filter(search_params)
#     end
#   end
#
# 機能:
#   - 許可されたパラメータのみを取得
#   - 空文字・空白を nil に変換
#   - 有効な値のみをハッシュに追加
module SearchAndFilterConcern
  extend ActiveSupport::Concern

  # 検索パラメータを取得して正規化
  #
  # 空文字・空白のみの値は nil に変換し、有効な値のみを返す
  #
  # @param allowed_keys [Array<Symbol>] 許可するパラメータキー
  # @return [Hash] 正規化された検索パラメータ
  #
  # @example
  #   get_and_normalize_search_params(:name, :category_id)
  #   # params: { name: "  ", category_id: "1" }
  #   # => { category_id: "1" }
  def get_and_normalize_search_params(*allowed_keys)
    search_params = {}

    params.permit(allowed_keys).each do |key, value|
      # strip.presence で空文字・空白を nil にする
      normalized_value = value.to_s.strip.presence

      # 有効な値のみハッシュに追加
      search_params[key.to_sym] = normalized_value if normalized_value
    end

    search_params
  end

  private

  # 継承先コントローラーで実装されるメソッド
  def search_params; end
end
