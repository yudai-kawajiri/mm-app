# frozen_string_literal: true

class DashboardsController < AuthenticatedController
  def index
    @show_welcome_modal = session.delete(:first_login)

    # 権限別のダッシュボード表示
    case
    when current_user.super_admin?
      render_admin_dashboard
    when current_user.company_admin?
      render_company_admin_dashboard
    else
      render_store_user_dashboard
    end
  end

  private

  # システム管理者用ダッシュボード
  def render_admin_dashboard
    @pending_users_count = User.where(approved: false).count
    @tenants_count = Tenant.count
    @stores_count = Store.count
    @recent_logs = SystemLog.order(created_at: :desc).limit(10)

    render 'dashboards/admin_dashboard'
  end

  # 会社管理者用ダッシュボード
  def render_company_admin_dashboard
    @pending_users_count = current_user.tenant.users.where(approved: false).count
    @stores_count = current_user.tenant.stores.count
    @recent_logs = SystemLog.where(tenant_id: current_user.tenant_id).order(created_at: :desc).limit(10)

    render 'dashboards/company_admin_dashboard'
  end

  # 店舗ユーザー用ダッシュボード（現在の数値管理）
  def render_store_user_dashboard
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month
    @selected_date = Date.new(@year, @month, 1)

    @forecast_service = NumericalForecastService.new(
      year: @year,
      month: @month
    )

    @forecast_data = @forecast_service.calculate
    @monthly_budget = @forecast_service.send(:find_monthly_budget)

    weather_service = WeatherService.new
    @weather_forecast = weather_service.fetch_weekly_forecast

    # 店舗管理者: 承認待ちユーザー通知
    if current_user.store_admin?
      @pending_users_count = current_user.store.users.where(approved: false).count
    end

    render 'dashboards/index'
  end
end
