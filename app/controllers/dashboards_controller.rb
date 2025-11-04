class DashboardsController < AuthenticatedController
  # グラフ表示の月数。0..5 は 6ヶ月間を意味するため、6を設定。
  PAST_MONTHS_FOR_CHART = 6

  def index
    # 当月のデータを取得（売上予算ダッシュボードと同じロジック）
    @forecast_service = NumericalForecastService.new(
      user: current_user,
      year: Date.current.year,
      month: Date.current.month
    )

    @forecast_data = @forecast_service.calculate
    @monthly_budget = @forecast_service.budget

    # グラフ用データ（過去6ヶ月）
    # 0..5 ではなく、0からPAST_MONTHS_FOR_CHART - 1 までの範囲を指定
    @chart_data = (0...(PAST_MONTHS_FOR_CHART)).map do |i|
      date = i.months.ago.beginning_of_month
      month_start = date.beginning_of_month
      month_end = date.end_of_month

      target = current_user.daily_targets
                            .where(target_date: month_start..month_end)
                            .sum(:target_amount)

      actual = current_user.plan_schedules
                            .where(scheduled_date: month_start..month_end)
                            .sum(:actual_revenue)

      {
        month: "#{date.year}/#{date.month}",
        target: target,
        actual: actual
      }
    end.reverse
  end
end