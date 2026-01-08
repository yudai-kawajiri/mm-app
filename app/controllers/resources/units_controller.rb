# frozen_string_literal: true

class Resources::UnitsController < AuthenticatedController
  include SortableController

  define_search_params :q, :category, :sort_by

  define_sort_options(
    name: -> { order(:reading) },
    category: -> { order(:category, :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  find_resource :unit, only: [ :show, :edit, :update, :destroy, :copy ]
  before_action :set_unit, only: [ :show, :edit, :update, :destroy, :copy ]
  before_action :require_store_user

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
    @unit.company_id = current_company.id
    @unit.store_id = current_user.store_id
  end

  def create
    @unit = Resources::Unit.new(unit_params)
    @unit.user_id = current_user.id
    @unit.company_id = current_company.id
    @unit.store_id = current_user.store_id if @unit.store_id.blank?
    respond_to_save(@unit, success_path: -> { resources_unit_path(@company_from_path, @unit) })
  end

  def show; end

  def edit; end

  def update
    @unit.assign_attributes(unit_params)
    respond_to_save(@unit, success_path: -> { resources_unit_path(@company_from_path, @unit) })
  end

  def destroy
    respond_to_destroy(@unit, success_path: scoped_path(:resources_units_path))
  end

  def copy
    @unit.create_copy(user: current_user)
    redirect_to scoped_path(:resources_units_path), notice: t("flash_messages.copy.success",
                                                  resource: @unit.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Unit copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to scoped_path(:resources_units_path), alert: t("flash_messages.copy.failure",
                                                resource: @unit.class.model_name.human)
  end

  def scoped_units
    case current_user.role
    when "store_admin", "general"
      Resources::Unit.where(store_id: current_user.store_id)
    when "company_admin"
      if session[:current_store_id].present?
        Resources::Unit.where(company_id: current_company.id, store_id: session[:current_store_id])
      else
        Resources::Unit.where(company_id: current_company.id)
      end
    when "super_admin"
      Resources::Unit.all
    else
      Resources::Unit.none
    end
  end

  def set_unit
    @unit = scoped_units.find(params[:id])
  end

  private

  def unit_params
    params.require(:resources_unit).permit(:name, :reading, :category, :description)
  end
end
