# frozen_string_literal: true

class DashboardsController < AuthenticatedController
  layout "dashboard"
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
    if session[:current_company_id].present?
      # 会社選択時: 会社管理者と同じダッシュボードを表示
      company = Company.find(session[:current_company_id])
      @pending_users_count = AdminRequest.for_company(company).pending.count
      @stores_count = company.stores.count

      if session[:current_store_id].present?
        # 店舗選択時: その店舗のログのみ
        store = Store.find(session[:current_store_id])
        @recent_logs = PaperTrail::Version
          .joins("LEFT JOIN users ON versions.whodunnit = CAST(users.id AS VARCHAR)")
          .where("users.store_id = ? OR versions.whodunnit IS NULL", store.id)
          .order("versions.created_at DESC")
          .limit(10)
      else
        # 全店舗選択時: 会社内の全ログ
        @recent_logs = PaperTrail::Version
          .joins("LEFT JOIN users ON versions.whodunnit = CAST(users.id AS VARCHAR)")
          .where("users.company_id = ? OR versions.whodunnit IS NULL", company.id)
          .order("versions.created_at DESC")
          .limit(10)
      end

      render "dashboards/company_admin_dashboard"
    else
      # 全会社モード: システム管理者ダッシュボード
      @pending_users_count = AdminRequest.pending.count
      @companies_count = Company.count
      @stores_count = Store.count

      # システム管理者: 全ログ表示
      @recent_logs = PaperTrail::Version.order(created_at: :desc).limit(10)

      render "dashboards/admin_dashboard"  # ← 全会社モード専用ビュー
    end
  end

  # 会社管理者用ダッシュボード
  def render_company_admin_dashboard
    # 承認待ちユーザー数: 自テナントのみ (AdminRequest の pending のみ)
    @pending_users_count = AdminRequest.for_company(current_user.company).pending.count
    @stores_count = current_user.company.stores.count

    # 会社管理者: テナント内のログをフィルタ
    if session[:current_store_id].present?
      # 特定店舗選択時: その店舗に関連するログのみ
      store = Store.find(session[:current_store_id])
      @recent_logs = PaperTrail::Version
        .joins("LEFT JOIN users ON versions.whodunnit = CAST(users.id AS VARCHAR)")
        .where("users.store_id = ? OR versions.whodunnit IS NULL", store.id)
        .order("versions.created_at DESC")
        .limit(10)
    else
      # 全店舗選択時: テナント内の全ログ
      @recent_logs = PaperTrail::Version
        .joins("LEFT JOIN users ON versions.whodunnit = CAST(users.id AS VARCHAR)")
        .where("users.company_id = ? OR versions.whodunnit IS NULL", current_user.company_id)
        .order("versions.created_at DESC")
        .limit(10)
    end

    render "dashboards/company_admin_dashboard"
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

    # 店舗管理者: 承認待ちユーザー通知 (AdminRequest の pending のみ)
    if current_user.store_admin?
      @pending_users_count = AdminRequest.for_company(current_user.company)
                                          .where(store: current_user.store)
                                          .pending
                                          .count
    end

    render "dashboards/index"
  end
end
