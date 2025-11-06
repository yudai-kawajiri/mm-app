class MaterialsController < AuthenticatedController
  define_search_params :q, :category_id
  before_action -> { load_categories_for("material", as: :material) }, only: [ :index, :new, :edit, :create, :update ]
  find_resource :material, only: [ :show, :edit, :update, :destroy ]

  def index
    @materials = apply_pagination(
      Material.includes(:category, :unit_for_product, :unit_for_order)
              .search_and_filter(search_params)
              .ordered
    )
    @search_categories = @material_categories  # ← 追加
    set_search_term_for_view
  end

  def show; end

  def new
    @material = current_user.materials.build
  end

  def create
    @material = current_user.materials.build(material_params)
    respond_to_save(@material, success_path: @material)
  end

  def edit; end

  def update
    @material.assign_attributes(material_params)
    respond_to_save(@material, success_path: @material)
  end

  def destroy
    respond_to_destroy(@material, success_path: materials_url)
  end

  def reorder
    material_ids = reorder_params[:material_ids]

    Rails.logger.debug "=== Received material_ids: #{material_ids.inspect}"

    Material.update_display_orders(material_ids)
    head :ok
  end

  private

  def material_params
    params.require(:material).permit(
    :name, :category, :unit, :unit_weight_for_product, :unit_weight_for_order,
    :minimum_order_quantity, :default_unit_weight, :order_group_name,
    :measurement_type, :unit_count_for_product, :unit_count_for_order, :order_group_id
  )
  end

  def reorder_params
    params.permit(material_ids: [])
  end
end
