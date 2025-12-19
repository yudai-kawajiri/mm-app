# frozen_string_literal: true

# MaterialOrderGroupsController
#
# 発注グループ（MaterialOrderGroup）のCRUD操作を管理
#
# 【実装のポイント】
# - マルチテナント・店舗スコープを index/new/create に適用
# - scoped_material_order_groups により権限レベルに応じたデータ分離を実現
class Resources::MaterialOrderGroupsController < AuthenticatedController
  include SortableController

  define_search_params :q, :sort_by

  define_sort_options(
    name: -> { order(:reading) },
    created_at: -> { order(created_at: :desc) }
  )

  find_resource :material_order_group, only: [ :show, :edit, :update, :destroy, :copy ]
  before_action :set_material_order_group, only: [ :show, :edit, :update, :destroy, :copy ]

  def index
    base_query = scoped_material_order_groups
    sorted_query = apply_sort(base_query, default: "name")
    @material_order_groups = apply_pagination(sorted_query)
    set_search_term_for_view if respond_to?(:set_search_term_for_view, true)
  end

  def new
    @material_order_group = Resources::MaterialOrderGroup.new
    @material_order_group.user_id = current_user.id
    @material_order_group.tenant_id = current_tenant.id
    @material_order_group.store_id = current_store&.id
  end

  def create
    @material_order_group = Resources::MaterialOrderGroup.new(material_order_group_params)
    @material_order_group.user_id = current_user.id
    @material_order_group.tenant_id = current_tenant.id
    @material_order_group.store_id = current_store&.id if @material_order_group.store_id.blank?
    respond_to_save(@material_order_group)
  end

  def show; end

  def edit; end

  def update
    @material_order_group.assign_attributes(material_order_group_params)
    respond_to_save(@material_order_group)
  end

  def destroy
    respond_to_destroy(@material_order_group, success_path: resources_material_order_groups_url)
  end

  def copy
    @material_order_group.create_copy(user: current_user)
    redirect_to resources_material_order_groups_path, notice: t("flash_messages.copy.success",
                                                                  resource: @material_order_group.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "MaterialOrderGroup copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_material_order_groups_path, alert: t("flash_messages.copy.failure",
                                                                resource: @material_order_group.class.model_name.human)
  end

  def set_material_order_group
    @material_order_group = scoped_material_order_groups.find(params[:id])
  end


  def scoped_material_order_groups
    case current_user.role
    when 'store_admin', 'general'
      Resources::MaterialOrderGroup.where(store_id: current_user.store_id)
    when 'company_admin'
      if session[:current_store_id].present?
        Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id, store_id: session[:current_store_id])
      else
        Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id)
      end
    when 'super_admin'
      Resources::MaterialOrderGroup.all
    else
      Resources::MaterialOrderGroup.none
    end
  end
  private

  def material_order_group_params
    params.require(:resources_material_order_group).permit(:name, :reading, :description)
  end
end
