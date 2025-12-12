# frozen_string_literal: true

# MaterialsController
#
# 原材料（Material）のCRUD操作を管理
#
# 機能:
#   - 原材料の一覧表示（検索・カテゴリ―フィルタ・ページネーション・ソート機能）
#   - 原材料の作成・編集・削除
#   - 原材料のコピー
class Resources::MaterialsController < AuthenticatedController
  include SortableController

  # 検索パラメータの定義
  define_search_params :q, :category_id, :sort_by

  # ソートオプションの定義
  define_sort_options(
    display_order: -> { order(:display_order) },
    name: -> { order(:reading) },
    category: -> { joins(:category).order("categories.reading", :reading) },
    order_group: -> { left_joins(:order_group).order("material_order_groups.reading", :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  # リソース検索（show, edit, update, destroy, copy）
  find_resource :material, only: [ :show, :edit, :update, :destroy, :copy ]

  # 原材料一覧
  #
  # @return [void]
  def index
    @material_categories = Resources::Category.for_materials
    base_query = scoped_materials.includes(:category, :unit_for_product, :unit_for_order, :production_unit, :order_group)
    base_query = base_query.search_and_filter(search_params) if defined?(search_params)
    sorted_query = apply_sort(base_query, default: "name")
    @materials = apply_pagination(sorted_query)
    set_search_term_for_view if respond_to?(:set_search_term_for_view, true)
  end

  # 新規原材料作成フォーム
  #
  # @return [void]
  def new
    @material_categories = Resources::Category.material.where(user_id: current_user.id)
    @material = Resources::Material.new
    @material.user_id = current_user.id
    @material.tenant_id = current_tenant.id
    @material.store_id = current_store&.id
  end

  # 原材料を作成
  #
  # @return [void]
  def create
    @material = Resources::Material.new(material_params)
    @material.user_id = current_user.id
    @material.tenant_id = current_tenant.id
    @material.store_id = current_store&.id if @material.store_id.blank?
    respond_to_save(@material)
  end

  # 原材料詳細
  #
  # @return [void]
  def show; end

  # 原材料編集フォーム
  #
  # @return [void]
  def edit
    @material_categories = Resources::Category.material.where(user_id: current_user.id)
  end

  # 原材料を更新
  #
  # @return [void]
  def update
    @material.assign_attributes(material_params)
    respond_to_save(@material)
  end

  # 原材料を削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@material, success_path: resources_materials_url)
  end

  # 原材料をコピー
  #
  # @return [void]
  def copy
    @material.create_copy(user: current_user)
    redirect_to resources_materials_path, notice: t("flash_messages.copy.success",
                                                    resource: @material.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Material copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_materials_path, alert: t("flash_messages.copy.failure",
                                                    resource: @material.class.model_name.human)
  end

  # 並び替え順序を保存
  #
  # @return [void]
  def reorder
    params[:material_ids].each_with_index do |id, index|
      Resources::Material.find(id).update(display_order: index + 1)
    end

    flash[:notice] = t("sortable_table.saved")
    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
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
