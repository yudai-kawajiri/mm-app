module CategoryFetchable
  extend ActiveSupport::Concern

  private

  def fetch_categories_by_type(type_key)
    db_value = Category.category_types[type_key.to_sym]

    if db_value.present? || db_value == 0
      current_user.categories.where(category_type: db_value).order(:name)
    else
      Category.none
    end
  end

  # @search_categories (商品カテゴリ) を設定するメソッド
  def set_product_categories
    # @search_categories がビューで利用される変数名
    @search_categories = fetch_categories_by_type(:product)
  end

  # @material_categories (原材料カテゴリ) を設定するメソッド ★
  def set_material_categories
    # @material_categories がビューで利用される変数名
    @material_categories = fetch_categories_by_type(:material)
  end

  # カテゴリー取得メソッド
  def set_plan_categories
    # 計画カテゴリーは検索とフォームの両方で使うため、@search_categories に統一
    @search_categories = fetch_categories_by_type(:plan)

    # 商品カテゴリーはネストフォームで使用するため、@product_categories を設定
    @product_categories = fetch_categories_by_type(:product)
  end
end
