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
    display_order: -> { ordered },
    name: -> { order(:reading) },
    category: -> { joins(:category).order('categories.reading', :reading) },
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
    @product_categories = current_user.categories.for_products.ordered
  end

  # 新規商品作成フォーム
  #
  # @return [void]
  def new
    @product = current_user.products.build
    @product_categories = current_user.categories.for_products.ordered
    @material_categories = current_user.categories.for_materials
  end

  # 商品を作成
  #
  # @return [void]
  def create
    @product = current_user.products.build(product_params)

    # エラー時のrender用に変数を事前設定
    @product_categories = current_user.categories.for_products.ordered
    @material_categories = current_user.categories.for_materials

    respond_to_save(@product)
  end

  # 商品詳細
  #
  # @return [void]
  def show; end

  # 商品編集フォーム
  #
  # @return [void]
  def edit
    @product_categories = current_user.categories.for_products.ordered
    @material_categories = current_user.categories.for_materials
  end

  # 商品を更新
  #
  # @return [void]
  def update
    @product.assign_attributes(product_params)

    # エラー時のrender用に変数を事前設定
    @product_categories = current_user.categories.for_products.ordered
    @material_categories = current_user.categories.for_materials

    respond_to_save(@product)
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
    copied = @product.create_copy(user: current_user)
    redirect_to edit_resources_product_path(copied), notice: t('flash_messages.copy.success',
                                                                resource: @product.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Product copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_products_path, alert: t('flash_messages.copy.failure',
                                                  resource: @product.class.model_name.human)
  end

  # 並び替え順序を保存
  #
  # @return [void]
  def reorder
    params[:product_ids].each_with_index do |id, index|
      current_user.products.find(id).update(display_order: index + 1)
    end

    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  # 画像を削除
  #
  # @return [void]
  def purge_image
    @product.image.purge if @product.image.attached?
    redirect_to edit_resources_product_path(@product), notice: t('products.messages.image_deleted')
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def product_params
    params.require(:resources_product).permit(
      :name,
      :reading,
      :category_id,
      :item_number,
      :price,
      :status,
      :image,
      :note,
      :description,
      product_materials_attributes: [
        :id,
        :material_id,
        :quantity,
        :_destroy
      ]
    )
  end
end
