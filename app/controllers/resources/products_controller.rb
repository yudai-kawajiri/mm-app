# frozen_string_literal: true

# ProductsController
#
# 商品（Product）のCRUD操作を管理
#
# 機能:
#   - 商品の一覧表示（検索・カテゴリフィルタ・ページネーション・ソート機能）
#   - 商品の作成・編集・削除
#   - 商品のコピー機能
class Resources::ProductsController < AuthenticatedController
  include SortableController

  # 検索パラメータの定義
  define_search_params :q, :category_id, :sort_by

  # ソートオプションの定義
  define_sort_options(
    name: -> { order(:name) },
    category: -> { joins(:category).order('categories.name', :name) },
    created_at: -> { order(created_at: :desc) }
  )

  # リソース検索（show, edit, update, destroy, copy）
  find_resource :product, only: [:show, :edit, :update, :destroy, :copy]

  # 商品一覧
  #
  # @return [void]
  def index
    sorted_index(
      Resources::Product,
      default: 'name',
      scope: :all,
      includes: [:category, :product_materials]
    )
    @product_categories = current_user.categories.for_products
  end

  # 新規商品作成フォーム
  #
  # @return [void]
  def new
    @product = current_user.products.build
    @material_categories = current_user.categories.for_materials
  end

  # 商品を作成
  #
  # @return [void]
  def create
    @product = current_user.products.build(product_params)
    respond_to_save(@product, success_path: @product)
  end

  # 商品詳細
  #
  # @return [void]
  def show; end

  # 商品編集フォーム
  #
  # @return [void]
  def edit
    @material_categories = current_user.categories.for_materials  # ← 追加
  end

  # 商品を更新
  #
  # @return [void]
  def update
    @product.assign_attributes(product_params)
    respond_to_save(@product, success_path: @product)
  end

  # 商品を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@product, success_path: resources_products_url)
  end

  # 商品をコピー
  #
  # @return [void]
  def copy
    new_product = @product.deep_copy

    if new_product.save
      redirect_to edit_resources_product_path(new_product),
                  notice: t('products.copy.success')
    else
      redirect_to resources_products_path,
                  alert: t('products.copy.failure')
    end
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def material_params
    params.require(:resources_product).permit(
      :name,
      :category_id,
      :item_number,
      :price,
      :status,
      :image,
      :note,
      product_materials_attributes: [
        :id,
        :material_id,
        :quantity,
        :_destroy
      ]
    )
  end
end
