class ApplicationController < ActionController::Base
  layout :layout_by_resource

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit
  before_action :redirect_if_authenticated, if: -> { devise_controller? && action_name == "new" && controller_name == "sessions" }

  helper_method :current_tenant, :current_store

  before_action :auto_login_pending_user

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :invitation_code, :store_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(resource)
    if resource.can_manage_company? && session[:current_store_id].blank?
      first_store = resource.tenant&.stores&.first
      session[:current_store_id] = first_store&.id if first_store
    end

    authenticated_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  def layout_by_resource
    return "print" if action_name == "print"

    if devise_controller? && !user_signed_in?
      "application"
    elsif user_signed_in?
      "authenticated_layout"
    else
      "application"
    end
  end

  def user_for_paper_trail
    user_signed_in? ? current_user.id : nil
  end

  def info_for_paper_trail
    { store_id: current_store&.id }
  end

  def tenant_from_subdomain
    return @tenant_from_subdomain if defined?(@tenant_from_subdomain)

    host = request.host
    subdomain = if host.include?(".localhost")
      host.split(".").first
    else
      request.subdomain
    end

    @tenant_from_subdomain = if subdomain.present? && subdomain != "www"
      Tenant.find_by(subdomain: subdomain)
    else
      nil
    end
  end

  def current_tenant
    @current_tenant ||= current_user&.tenant || tenant_from_subdomain
  end

  def current_store
    @current_store ||= if current_user&.can_manage_company?
      current_tenant&.stores&.find_by(id: session[:current_store_id])
    else
      current_user&.store
    end
  end

  def scoped_monthly_budgets
    return Management::MonthlyBudget.none unless current_tenant
    Management::MonthlyBudget.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  def scoped_categories
    Resources::Category.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  def scoped_products
    Resources::Product.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  def scoped_materials
    Resources::Material.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  def scoped_plans
    Resources::Plan.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  def scoped_material_order_groups
    Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  def scoped_units
    Resources::Unit.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  def scoped_daily_targets
    return Management::DailyTarget.none unless current_tenant
    Management::DailyTarget.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  def scoped_plan_schedules
    return Planning::PlanSchedule.none unless current_tenant
    Planning::PlanSchedule.where(tenant_id: current_tenant.id, store_id: current_store&.id)
  end

  private

  def auto_login_pending_user
    return unless session[:pending_user_id].present?
    return if user_signed_in?
    
    user = User.find_by(id: session[:pending_user_id])
    if user
      sign_in(user)
      session.delete(:pending_user_id)
      flash[:notice] = 'アカウント登録が完了しました' if session[:first_login]
      session.delete(:first_login)
    else
      session.delete(:pending_user_id)
    end
  end

  def redirect_if_authenticated
    return unless user_signed_in?

    flash[:notice] = t("devise.failure.already_authenticated")
    redirect_to authenticated_root_path
  end
end
