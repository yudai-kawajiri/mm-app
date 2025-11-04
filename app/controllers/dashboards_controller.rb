class DashboardsController < AuthenticatedController
  def index
    # 年月パラメータ（デフォルトは当月）
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month
    @selected_date = Date.new(@year, @month, 1)

    # 選択された月のデータを取得
    @forecast_service = NumericalForecastService.new(
      user: current_user,
      year: @year,
      month: @month
    )

    @forecast_data = @forecast_service.calculate
    @monthly_budget = @forecast_service.budget

    # グラフ用データ（選択された月の累計推移）
    start_date = @selected_date.beginning_of_month
    end_date = @selected_date.end_of_month

    cumulative_target = 0
    cumulative_actual = 0

    @chart_data = (start_date..end_date).map do |date|
      # 日別目標を累計に加算
      daily_target = current_user.daily_targets
                                  .find_by(target_date: date)
      cumulative_target += (daily_target&.target_amount || 0)

      # 日別実績を累計に加算
      daily_actual = current_user.plan_schedules
                                  .where(scheduled_date: date)
                                  .sum(:actual_revenue)
      cumulative_actual += daily_actual

      {
        date: date.strftime("%-m/%-d"),
        target: cumulative_target,
        actual: cumulative_actual
      }
    end
  end
end
