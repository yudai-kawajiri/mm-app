# frozen_string_literal: true

class Resources::ProductsController < AuthenticatedController
  include SortableController

  define_search_params :q, :category_id, :sort_by

  define_sort_options(
    display_order: -> { by_display_order },
    name: -> { order(:reading) },
    category: -> { joins(:category).order("categories.reading", :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  find_resource :product, only: [ :show, :edit, :update, :destroy, :copy, :purge_image, :update_status ]

  # 商品一覧
  #
  # 【Eager Loading】
  # N+1クエリを防ぐため、以下を事前ロード:
  # - category: カテゴリ名表示
  # - image_attachment: 画像表示
  def index
    @product_categories = scoped_categories.for_products.ordered
    base_query = scoped_products.includes(:category, :image_attachment)
    base_query = base_query.search_and_filter(search_params) if defined?(search_params)
    sorted_query = apply_sort(base_query, default: "name")
    @products = apply_pagination(sorted_query)
    set_search_term_for_view if respond_to?(:set_search_term_for_view, true)
  end

  def new
    @product = Resources::Product.new
    @product.user_id = current_user.id
    @product.tenant_id = current_tenant.id
    @product.store_id = current_store&.id
    @product_categories = scoped_categories.for_products.ordered
    @material_categories = scoped_categories.for_materials
    @materials = scoped_materials.ordered
  end

  def create
    @product = Resources::Product.new(product_params)
    @product.user_id = current_user.id
    @product.tenant_id = current_tenant.id
    @product.store_id = current_store&.id if @product.store_id.blank?

    @product_categories = scoped_categories.for_products.ordered
    @material_categories = scoped_categories.for_materials
    @materials = scoped_materials.ordered

    respond_to_save(@product)
  end

  def show
    @product_materials = @product.product_materials.includes(:material, :unit).order(:id)
  end

  def edit
    @product_categories = scoped_categories.for_products.ordered
    @material_categories = scoped_categories.for_materials
    @materials = scoped_materials.ordered
  end

  def update
    @product.assign_attributes(product_params)

    @product_categories = scoped_categories.for_products.ordered
    @material_categories = scoped_categories.for_materials
    @materials = scoped_materials.ordered

    respond_to_save(@product)
  end

  def destroy
    respond_to_destroy(@product, success_path: resources_products_url)
  end

  def copy
    @product.create_copy(user: current_user)
    redirect_to resources_products_path, notice: t("flash_messages.copy.success",
                                                  resource: @product.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Product copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_products_path, alert: t("flash_messages.copy.failure",
                                                  resource: @product.class.model_name.human)
  end

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

  def reorder
    params[:product_ids].each_with_index do |id, index|
      Resources::Product.find(id).update(display_order: index + 1)
    end

    render json: { message: t("sortable_table.saved") }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: t("sortable_table.not_found") }, status: :not_found
  end

  def purge_image
    @product.image.purge if @product.image.attached?

    respond_to do |format|
      format.html { redirect_to edit_resources_product_path(@product), notice: t("products.messages.image_deleted") }
      format.json { head :no_content }
    end
  end

  def set_product
    @product = scoped_products.find(params[:id])
  end


  private

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
      materials = params[:resources_product][:product_materials_attributes]
      if materials.present?
        filtered_materials = materials.permit!.to_h.reject do |_key, attrs|
          attrs[:quantity].blank? || attrs[:quantity].to_f.zero?
        end
        whitelisted[:product_materials_attributes] = filtered_materials
      end
    end
  end
end
