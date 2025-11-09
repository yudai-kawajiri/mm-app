# frozen_string_literal: true

# PaginationConcern
#
# ページネーション機能を提供するConcern
#
# 使用例:
#   class ProductsController < ApplicationController
#     include PaginationConcern
#
#     def index
#       @products = Product.all
#       @products = apply_pagination(@products, max_per_page: 50)
#     end
#   end
#
# 依存: Kaminari gem
module PaginationConcern
  extend ActiveSupport::Concern

  # ページネーションを適用
  #
  # @param collection [ActiveRecord::Relation] ページネーション対象のコレクション
  # @param max_per_page [Integer] 1ページあたりの最大表示件数（デフォルト: 20）
  # @return [ActiveRecord::Relation] ページネーション適用後のコレクション
  def apply_pagination(collection, max_per_page: 20)
    collection.page(params[:page]).per(max_per_page)
  end
end
