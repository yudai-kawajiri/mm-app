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
    if current_user.company_admin?
      session[:current_store_id] = current_user.tenant.stores.first&.id
    elsif current_user.store_id.present?
      session[:current_store_id] = current_user.store_id
    end
    
    dashboards_path
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
    return nil unless session[:current_store_id]
    @current_store ||= current_user.tenant.stores.find_by(id: session[:current_store_id])
  end

  def scoped_monthly_budgets
    return Management::MonthlyBudget.none unless current_tenant
    if session[:current_store_id].present?
      Management::MonthlyBudget.where(tenant_id: current_tenant.id, store_id: session[:current_store_id])
    else
      Management::MonthlyBudget.where(tenant_id: current_tenant.id)
    end
  end

  def scoped_categories
    Rails.logger.info "[DEBUG SCOPED] session[:current_store_id] = #{session[:current_store_id].inspect}"
    Rails.logger.info "[DEBUG SCOPED] current_tenant.id = #{current_tenant&.id}"
    result = if session[:current_store_id].present?
      Resources::Category.where(tenant_id: current_tenant.id, store_id: session[:current_store_id])
    else
      Resources::Category.where(tenant_id: current_tenant.id)
    end
    Rails.logger.info "[DEBUG SCOPED] result.count = #{result.count}"
    result
  end

  def scoped_products
    if session[:current_store_id].present?
      Resources::Product.where(tenant_id: current_tenant.id, store_id: session[:current_store_id])
    else
      Resources::Product.where(tenant_id: current_tenant.id)
    end
  end

  def scoped_materials
    if session[:current_store_id].present?
      Resources::Material.where(tenant_id: current_tenant.id, store_id: session[:current_store_id])
    else
      Resources::Material.where(tenant_id: current_tenant.id)
    end
  end

  def scoped_plans
    if session[:current_store_id].present?
      Resources::Plan.where(tenant_id: current_tenant.id, store_id: session[:current_store_id])
    else
      Resources::Plan.where(tenant_id: current_tenant.id)
    end
  end

  def scoped_material_order_groups
    if session[:current_store_id].present?
      Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id, store_id: session[:current_store_id])
    else
      Resources::MaterialOrderGroup.where(tenant_id: current_tenant.id)
    end
  end

  def scoped_units
    if session[:current_store_id].present?
      Resources::Unit.where(tenant_id: current_tenant.id, store_id: session[:current_store_id])
    else
      Resources::Unit.where(tenant_id: current_tenant.id)
    end
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
