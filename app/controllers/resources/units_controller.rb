# frozen_string_literal: true

class Resources::UnitsController < AuthenticatedController
  include SortableController
  before_action :require_store_selected, only: [:new, :edit, :create, :update, :copy, :destroy]

  define_search_params :q, :category, :sort_by

  define_sort_options(
    name: -> { order(:reading) },
    category: -> { order(:category, :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  find_resource :unit, only: [ :show, :edit, :update, :destroy, :copy ]

  def index
    @units = scoped_units

    @units = apply_sort(@units, default: "name")

    if params[:category].present?
      @units = @units.filter_by_category(params[:category])
    end

    if params[:q].present?
      @units = @units.search_by_name(params[:q])
    end

    @units = @units.page(params[:page])
  end

  def new
    @unit = Resources::Unit.new
    @unit.user_id = current_user.id
    @unit.tenant_id = current_tenant.id
    @unit.store_id = current_store&.id
  end

  def create
    @unit = Resources::Unit.new(unit_params)
    @unit.user_id = current_user.id
    @unit.tenant_id = current_tenant.id
    @unit.store_id = current_store&.id if @unit.store_id.blank?
    respond_to_save(@unit)
  end

  def show; end

  def edit; end

  def update
    @unit.assign_attributes(unit_params)
    respond_to_save(@unit)
  end

  def destroy
    respond_to_destroy(@unit, success_path: resources_units_url)
  end

  def copy
    @unit.create_copy(user: current_user)
    redirect_to resources_units_path, notice: t("flash_messages.copy.success",
                                                  resource: @unit.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Unit copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_units_path, alert: t("flash_messages.copy.failure",
                                                resource: @unit.class.model_name.human)
  end

  private

  def unit_params
    params.require(:resources_unit).permit(:name, :reading, :category, :description)
  end
end
