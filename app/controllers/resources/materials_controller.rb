# frozen_string_literal: true

class Resources::MaterialsController < AuthenticatedController
  include SortableController


  define_search_params :q, :category_id, :sort_by

  define_sort_options(
    display_order: -> { order(:display_order) },
    name: -> { order(:reading) },
    category: -> { joins(:category).order("categories.reading", :reading) },
    order_group: -> { left_joins(:order_group).order("material_order_groups.reading", :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  skip_before_action :authenticate_user!
  before_action :authenticate_user!
  before_action :require_store_user
  before_action :set_material, only: [ :show, :edit, :update, :destroy, :copy ]

  # 原材料一覧
  #
  # 【Eager Loading】
  # N+1クエリを防ぐため、関連データを事前ロード:
  # - category, unit_for_product, unit_for_order, production_unit, order_group
  #
  # 【データスコープ】
  # scoped_materials で現在のテナント・店舗に応じたデータのみ取得
  def index
    @material_categories = scoped_categories.for_materials
    base_query = scoped_materials.includes(:category, :unit_for_product, :unit_for_order, :production_unit, :order_group)
    base_query = base_query.search_and_filter(search_params) if defined?(search_params)
    sorted_query = apply_sort(base_query, default: "name")
    @materials = apply_pagination(sorted_query)
    set_search_term_for_view if respond_to?(:set_search_term_for_view, true)
  end

  # 新規原材料作成フォーム
  #
  # 【自動設定】
  # user_id, company_id, store_id を自動設定
  def new
    @material_categories = scoped_categories.for_materials
    @production_units = scoped_units.where(category: :manufacturing).ordered
    @order_units = scoped_units.where(category: :ordering).ordered
    @manufacturing_units = scoped_units.where(category: :production).ordered
    @material_order_groups = scoped_material_order_groups.ordered
    @material = Resources::Material.new
    @material.user_id = current_user.id
    @material.company_id = current_company.id
    @material.store_id = current_user.store_id
  end

  # 原材料を作成
  #
  # 【自動設定】
  # user_id, company_id, store_id を自動設定（store_id が空の場合のみ）
  def create
    @material_categories = scoped_categories.for_materials
    @production_units = scoped_units.where(category: :manufacturing).ordered
    @order_units = scoped_units.where(category: :ordering).ordered
    @manufacturing_units = scoped_units.where(category: :production).ordered
    @material_order_groups = scoped_material_order_groups.ordered
    @material = Resources::Material.new(material_params)
    @material.user_id = current_user.id
    @material.company_id = current_company.id
    @material.store_id = current_user.store_id if @material.store_id.blank?
    respond_to_save(@material, success_path: -> { scoped_path(:resources_material_path, @material) })
  end

  def show; end

  def edit
    @material_categories = scoped_categories.for_materials
    @production_units = scoped_units.where(category: :manufacturing).ordered
    @order_units = scoped_units.where(category: :ordering).ordered
    @manufacturing_units = scoped_units.where(category: :production).ordered
    @material_order_groups = scoped_material_order_groups.ordered
  end

  def update
    @material_categories = scoped_categories.for_materials
    @production_units = scoped_units.where(category: :manufacturing).ordered
    @order_units = scoped_units.where(category: :ordering).ordered
    @manufacturing_units = scoped_units.where(category: :production).ordered 
    @material_order_groups = scoped_material_order_groups.ordered
    @material.assign_attributes(material_params)
    respond_to_save(@material, success_path: -> { scoped_path(:resources_material_path, @material) })
  end

  def destroy
    respond_to_destroy(@material, success_path: scoped_path(:resources_materials_path))
  end

  # 原材料をコピー
  #
  # 【注意】
  def copy
    @material.create_copy(user: current_user)
    redirect_to scoped_path(:resources_materials_path), notice: t("flash_messages.copy.success",
                                                    resource: @material.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Material copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to scoped_path(:resources_materials_path), alert: t("flash_messages.copy.failure",
                                                    resource: @material.class.model_name.human)
  end

  def reorder
    params[:material_ids].each_with_index do |id, index|
      Resources::Material.find(id).update(display_order: index + 1)
    end

    render json: { message: t("flash_messages.sortable_table.messages.saved") }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: t("flash_messages.sortable_table.messages.not_found") }, status: :not_found
  end

  def fetch_product_unit_data
    @material = scoped_materials.find(params[:id])

    render json: {
      unit_id: @material.unit_for_product_id,
      unit_name: @material.unit_for_product&.name
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: t("materials.not_found") }, status: :not_found
  end



  def scoped_materials
    case current_user.role
    when "store_admin", "general"
      Resources::Material.where(store_id: current_user.store_id)
    when "company_admin"
      if session[:current_store_id].present?
        Resources::Material.where(company_id: current_company.id, store_id: session[:current_store_id])
      else
        Resources::Material.where(company_id: current_company.id)
      end
    when "super_admin"
      Resources::Material.all
    else
      Resources::Material.none
    end
  end
  private

  def material_params
    params.require(:resources_material).permit(
      :name,
      :reading,
      :category_id,
      :unit_for_product_id,
      :default_unit_weight,
      :measurement_type,
      :unit_weight_for_order,
      :pieces_per_order_unit,
      :unit_for_order_id,
      :production_unit_id,
      :order_group_id,
      :description
    )
  end
end

  private

  def set_material
    @material = scoped_materials.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = t("flash_messages.not_authorized")
    redirect_to company_dashboards_path(company_slug: current_company.slug)
  end
