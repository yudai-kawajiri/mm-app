# frozen_string_literal: true

# CategoryFetchable
#
# カテゴリー種別ごとの取得機能を提供するConcern
#
# 使用例:
#   class ProductsController < ApplicationController
#     include CategoryFetchable
#     before_action :set_product_categories, only: [:new, :edit]
#   end
#
# 使用コントローラー: Products, Materials, Plans
module CategoryFetchable
  extend ActiveSupport::Concern

  private

  # カテゴリー種別でカテゴリーを取得
  #
  # @param type_key [String, Symbol] カテゴリー種別（:product, :material, :plan）
  # @return [ActiveRecord::Relation] カテゴリーのコレクション
  def fetch_categories_by_type(type_key)
    db_value = Resources::Category.category_types[type_key.to_sym]

    if db_value.present? || db_value == 0
      Resources::Category.where(category_type: db_value).order(:name)
    else
      Resources::Category.none
    end
  end

  # 製品カテゴリーを設定
  #
  # @return [void]
  def set_product_categories
    @search_categories = fetch_categories_by_type(:product)
  end

  # 材料カテゴリーを設定
  #
  # @return [void]
  def set_material_categories
    @material_categories = fetch_categories_by_type(:material)
  end

  # 計画カテゴリーと製品カテゴリーを設定
  #
  # 計画フォームでは製品選択のため、両方のカテゴリーが必要
  #
  # @return [void]
  def set_plan_categories
    # 計画カテゴリー（検索とフォーム用）
    @search_categories = fetch_categories_by_type(:plan)

    # 製品カテゴリー（ネストフォーム用）
    @product_categories = fetch_categories_by_type(:product)
  end
end
