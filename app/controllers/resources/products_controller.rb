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
  before_action :require_store_user

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
    @product.company_id = current_company.id
    @product.store_id = current_user.store_id
    @product_categories = scoped_categories.for_products.ordered
    @material_categories = scoped_categories.for_materials
    @materials = scoped_materials.ordered
  end

  def create
    @product = Resources::Product.new(product_params)
    @product.user_id = current_user.id
    @product.company_id = current_company.id
    @product.store_id = current_user.store_id if @product.store_id.blank?

    @product_categories = scoped_categories.for_products.ordered
    @material_categories = scoped_categories.for_materials
    @materials = scoped_materials.ordered

    respond_to_save(@product, success_path: -> { scoped_path(:resources_product_path, @product) })
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

    respond_to_save(@product, success_path: -> { scoped_path(:resources_product_path, @product) })
  end

  def destroy
    respond_to_destroy(@product, success_path: company_resources_products_path(company_slug: current_company.slug))
  end

  def copy
    @product.create_copy(user: current_user)
    redirect_to company_resources_products_path(company_slug: current_company.slug),
                notice: t("flash_messages.copy.success", resource: @product.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Product copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to company_resources_products_path(company_slug: current_company.slug),
                alert: t("flash_messages.copy.failure", resource: @product.class.model_name.human)
  end

  def update_status
    if @product.update(status: params[:status])
      redirect_to company_resources_products_path(company_slug: current_company.slug),
                  notice: t("resources.products.messages.status_updated",
                            name: @product.name,
                            status: t("activerecord.enums.resources/product.status.#{@product.status}"))
    else
      error_messages = @product.errors.full_messages.join("、")
      redirect_to company_resources_products_path(company_slug: current_company.slug),
                  alert: error_messages
    end
  end

  def reorder
    params[:product_ids].each_with_index do |id, index|
      Resources::Product.find(id).update(display_order: index + 1)
    end

    render json: { message: t("flash_messages.sortable_table.messages.saved") }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: t("flash_messages.sortable_table.messages.not_found") }, status: :not_found
  end

  def purge_image
    @product.image.purge if @product.image.attached?

    respond_to do |format|
      format.html { redirect_to edit_company_resources_product_path(company_slug: current_company.slug, id: @product.id), notice: t("products.messages.image_deleted") }
      format.json { head :no_content }
    end
  end

  def set_product
    @product = scoped_products.find(params[:id])
  end

  def scoped_products
    case current_user.role
    when "store_admin", "general"
      Resources::Product.where(store_id: current_user.store_id)
    when "company_admin"
      if session[:current_store_id].present?
        Resources::Product.where(company_id: current_company.id, store_id: session[:current_store_id])
      else
        Resources::Product.where(company_id: current_company.id)
      end
    when "super_admin"
      Resources::Product.all
    else
      Resources::Product.none
    end
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
          # _destroy が設定されている場合は除外しない（削除処理のため Rails に渡す必要がある）
          next false if attrs["_destroy"].to_s == "1" || attrs["_destroy"].to_s == "true"

          # material_id が空の場合のみ除外
          attrs["material_id"].blank?
        end
        whitelisted[:product_materials_attributes] = filtered_materials
      end
    end
  end
end
