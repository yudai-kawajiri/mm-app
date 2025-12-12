# frozen_string_literal: true

# ProductsController
#
# 商品（Product）のCRUD操作を管理
#
# 機能:
#   - 商品の一覧表示（検索・カテゴリ―フィルタ・ページネーション・ソート機能）
#   - 商品の作成・編集・削除
#   - 商品のコピー機能
class Resources::ProductsController < AuthenticatedController
  include SortableController

  # 検索パラメータの定義
  define_search_params :q, :category_id, :sort_by

  # ソートオプションの定義
  define_sort_options(
    display_order: -> { by_display_order },
    name: -> { order(:reading) },
    category: -> { joins(:category).order("categories.reading", :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  # リソース検索（show, edit, update, destroy, copy）
  find_resource :product, only: [ :show, :edit, :update, :destroy, :copy, :purge_image, :update_status ]

  # 商品一覧
  #
  # @return [void]
  def index
    @product_categories = Resources::Category.for_products.ordered
    base_query = scoped_products.includes(:category, :image_attachment)
    base_query = base_query.search_and_filter(search_params) if defined?(search_params)
    sorted_query = apply_sort(base_query, default: "name")
    @products = apply_pagination(sorted_query)
    set_search_term_for_view if respond_to?(:set_search_term_for_view, true)
  end

  # 新規商品作成フォーム
  #
  # @return [void]
  def new
    @product = Resources::Product.new
    @product.user_id = current_user.id
    @product.tenant_id = current_tenant.id
    @product.store_id = current_store&.id
    @product_categories = Resources::Category.for_products.ordered
    @material_categories = Resources::Category.for_materials
  end

  # 商品を作成
  #
  # @return [void]
  def create
    @product = Resources::Product.new(product_params)
    @product.user_id = current_user.id
    @product.tenant_id = current_tenant.id
    @product.store_id = current_store&.id if @product.store_id.blank?

    # エラー時のrender用に変数を事前設定
    @product_categories = Resources::Category.for_products.ordered
    @material_categories = Resources::Category.for_materials

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
    @product_categories = Resources::Category.for_products.ordered
    @material_categories = Resources::Category.for_materials
  end

  # 商品を更新
  #
  # @return [void]
  def update
    @product.assign_attributes(product_params)

    # エラー時のrender用に変数を事前設定
    @product_categories = Resources::Category.for_products.ordered
    @material_categories = Resources::Category.for_materials

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
    @product.create_copy(user: current_user)
    redirect_to resources_products_path, notice: t("flash_messages.copy.success",
                                                   resource: @product.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Product copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_products_path, alert: t("flash_messages.copy.failure",
                                                  resource: @product.class.model_name.human)
  end

  # 商品のステータスを更新
  #
  # @return [void]
  def update_status
  if @product.update(status: params[:status])
    redirect_to resources_products_path,
                notice: t("products.messages.status_updated",
                          name: @product.name,
                          status: t("activerecord.enums.resources/product.status.#{@product.status}"))
  else
    error_messages = @product.errors.full_messages.join("、")
    redirect_to resources_products_path,
                alert: error_messages
  end
  end

  # 並び替え順序を保存
  #
  # @return [void]
  def reorder
    params[:product_ids].each_with_index do |id, index|
      Resources::Product.find(id).update(display_order: index + 1)
    end

    flash[:notice] = t("sortable_table.saved")
    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  # 画像を削除
  #
  # @return [void]
  def purge_image
    @product.image.purge if @product.image.attached?

    respond_to do |format|
      format.html { redirect_to edit_resources_product_path(@product), notice: t("products.messages.image_deleted") }
      format.json { head :no_content }
    end
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
      :description
    ).tap do |whitelisted|
      # ネストされた属性（ハッシュ形式）を手動で処理
      # 文字列キー（"0", "new_1763555897631"など）を許可するため
      materials = params[:resources_product][:product_materials_attributes]
      if materials.present?
        # 数量が空または0のレコードを除外
        filtered_materials = materials.permit!.to_h.reject do |_key, attrs|
          attrs[:quantity].blank? || attrs[:quantity].to_f.zero?
        end
        whitelisted[:product_materials_attributes] = filtered_materials
      end
    end
  end
end
