class ApplicationController < ActionController::Base
  layout :layout_by_resource

  before_action :authenticate_user!, unless: :public_page?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit
  before_action :redirect_if_authenticated, if: -> { devise_controller? && action_name == "new" && controller_name == "sessions" }
  before_action :auto_login_pending_user
  before_action :set_current_company

  helper_method :current_company, :current_store

  private

  def public_page?
    devise_controller? ||
    controller_name == 'landing' ||
    controller_name == 'application_requests' ||
    controller_name == 'static_pages' ||
    controller_name == 'contacts'
  end

    def set_current_company
      if params[:company_slug].present?
        if params[:company_slug] == 'admin'
          # 全会社モード: セッションをクリア
          session[:current_company_id] = nil
          session[:current_store_id] = nil
          @company_from_path = nil
        else
          # 特定の会社: セッションに保存
          @company_from_path = Company.find_by(slug: params[:company_slug])
          session[:current_company_id] = @company_from_path&.id if @company_from_path
        end
      end
    end

  def scoped_path(path_method, *args)
    return send(path_method, *args) unless current_company.present?

    if path_method.to_s =~ /\A(new|edit)_(.+)/
      action_prefix = Regexp.last_match(1)
      rest = Regexp.last_match(2)
      company_method_name = "#{action_prefix}_company_#{rest}"
    else
      company_method_name = "company_#{path_method}"
    end

    begin
      send(company_method_name, *args, company_slug: current_company.slug)
    rescue NoMethodError => e
      Rails.logger.debug "Path fallback for #{path_method}: #{e.message}"
      begin
        send(path_method, *args)
      rescue NoMethodError => fallback_error
        Rails.logger.error "Path generation completely failed for #{path_method}: #{fallback_error.message}"
        "#"
      end
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :invitation_code, :store_id ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def after_sign_in_path_for(resource)
    if current_user.company_admin?
      session[:current_store_id] = nil
    elsif current_user.store_id.present?
      session[:current_store_id] = current_user.store_id
    end

    current_company ? company_dashboards_path(company_slug: current_company.slug) : company_dashboards_path(company_slug: current_user.company.slug)
  end

  def layout_by_resource
    return "print" if action_name == "print"

    if devise_controller?
      "application"
    elsif request.env['warden']&.user
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

  def company_from_path
    return nil unless params[:company_slug].present?
    @company_from_path ||= Company.find_by(slug: params[:company_slug])
  end

  helper_method :current_company
  def current_company
    return @current_company if defined?(@current_company)

    if current_user&.super_admin?
      @current_company = session[:current_company_id].present? ? Company.find_by(id: session[:current_company_id]) : nil
    else
      @current_company = current_user&.company || company_from_path
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

  rescue_from ActionController::RoutingError, with: :handle_routing_error

  def handle_routing_error(exception)
    logger.error "Routing Error: #{exception.message}"
    redirect_to company_dashboards_path(company_slug: current_company.slug), alert: t('errors.page_not_found')
  end

  def auto_login_pending_user
    return unless session[:pending_user_id].present?
    return if user_signed_in?

    user = User.find_by(id: session[:pending_user_id])
    if user
      sign_in(user)
      session.delete(:pending_user_id)
      flash[:notice] = t("helpers.notice.account_registered") if session[:first_login]
      session.delete(:first_login)
    else
      session.delete(:pending_user_id)
    end
  end

  def redirect_if_authenticated
    return unless user_signed_in?

    flash[:notice] = t("devise.failure.already_authenticated")
    redirect_to company_dashboards_path(company_slug: current_company.slug)
  end
end

  # Deviseパス用のヘルパー
  def devise_scoped_path(path_method, resource_name = :user)
    if current_company.present?
      send(path_method, company_slug: current_company.slug)
    else
      send(path_method)
    end
  rescue NoMethodError => e
    Rails.logger.error "Devise path generation failed for #{path_method}: #{e.message}"
    "#"
  end
