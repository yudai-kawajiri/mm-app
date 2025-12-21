class ApplicationController < ActionController::Base
  layout :layout_by_resource

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit
  before_action :redirect_if_authenticated, if: -> { devise_controller? && action_name == "new" && controller_name == "sessions" }

  helper_method :current_company, :current_store

  before_action :auto_login_pending_user
  before_action :check_super_admin_subdomain

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :invitation_code, :store_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(resource)
    if current_user.company_admin?
      # 会社管理者はデフォルトで全店舗モード（session[:current_store_id] = nil）
      session[:current_store_id] = nil
    elsif current_user.store_id.present?
      # 店舗管理者は自店舗を設定
      session[:current_store_id] = current_user.store_id
    end

    authenticated_root_path
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

  def company_from_subdomain
    return @company_from_subdomain if defined?(@company_from_subdomain)

    host = request.host
    subdomain = if host.include?(".localhost")
      host.split(".").first
    else
      request.subdomain
    end

    @company_from_subdomain = if subdomain.present? && subdomain != "www"
      Company.find_by(subdomain: subdomain)
    else
      nil
    end
  end

  def current_company
    return @current_company if defined?(@current_company)
    
    # システム管理者の場合: session[:current_company_id] でテナントを切り替え
    if current_user&.super_admin?
      @current_company = session[:current_company_id].present? ? Company.find_by(id: session[:current_company_id]) : nil
    else
      # 会社管理者・店舗管理者: 所属テナント、またはサブドメインから取得
      @current_company = current_user&.company || company_from_subdomain
    end
    
    @current_company
  end

  def current_store
    return nil unless session[:current_store_id]
    @current_store ||= current_user.company.stores.find_by(id: session[:current_store_id])
  end

  def scoped_monthly_budgets
    return Management::MonthlyBudget.none unless current_company
    if session[:current_store_id].present?
      Management::MonthlyBudget.where(company_id: current_company.id, store_id: session[:current_store_id])
    else
      Management::MonthlyBudget.where(company_id: current_company.id)
    end
  end

  def scoped_categories
    Rails.logger.info "[DEBUG SCOPED] session[:current_store_id] = #{session[:current_store_id].inspect}"
    Rails.logger.info "[DEBUG SCOPED] current_company.id = #{current_company&.id}"
    result = if session[:current_store_id].present?
      Resources::Category.where(company_id: current_company.id, store_id: session[:current_store_id])
    else
      Resources::Category.where(company_id: current_company.id)
    end
    Rails.logger.info "[DEBUG SCOPED] result.count = #{result.count}"
    result
  end

  def scoped_products
    if session[:current_store_id].present?
      Resources::Product.where(company_id: current_company.id, store_id: session[:current_store_id])
    else
      Resources::Product.where(company_id: current_company.id)
    end
  end

  def scoped_materials
    if session[:current_store_id].present?
      Resources::Material.where(company_id: current_company.id, store_id: session[:current_store_id])
    else
      Resources::Material.where(company_id: current_company.id)
    end
  end

  def scoped_plans
    if session[:current_store_id].present?
      Resources::Plan.where(company_id: current_company.id, store_id: session[:current_store_id])
    else
      Resources::Plan.where(company_id: current_company.id)
    end
  end

  def scoped_material_order_groups
    if session[:current_store_id].present?
      Resources::MaterialOrderGroup.where(company_id: current_company.id, store_id: session[:current_store_id])
    else
      Resources::MaterialOrderGroup.where(company_id: current_company.id)
    end
  end

  def scoped_units
    if session[:current_store_id].present?
      Resources::Unit.where(company_id: current_company.id, store_id: session[:current_store_id])
    else
      Resources::Unit.where(company_id: current_company.id)
    end
  end

  def scoped_daily_targets
    return Management::DailyTarget.none unless current_company
    Management::DailyTarget.where(company_id: current_company.id, store_id: current_store&.id)
  end

  def scoped_plan_schedules
    return Planning::PlanSchedule.none unless current_company
    Planning::PlanSchedule.where(company_id: current_company.id, store_id: current_store&.id)
  end

  # システム管理者は admin サブドメインのみアクセス可能
  def check_super_admin_subdomain
    if user_signed_in? && current_user.super_admin? && request.subdomain != 'admin'
      sign_out current_user
      flash[:alert] = t('errors.invalid_subdomain_access')
      redirect_to new_user_session_url(subdomain: 'admin'), allow_other_host: true
    end
  end
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
