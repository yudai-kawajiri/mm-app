# frozen_string_literal: true

# DashboardsController
#
# ダッシュボード画面の表示を管理
#
# 機能:
#   - 月次予測データの表示
#   - 天気予報の表示
class DashboardsController < AuthenticatedController
  # ダッシュボード画面
  #
  # @return [void]
  def index
    # 年月パラメータ（デフォルトは当月）
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month
    @selected_date = Date.new(@year, @month, 1)

    # 選択された月のデータを取得
    @forecast_service = NumericalForecastService.new(
      year: @year,
      month: @month
    )

    @forecast_data = @forecast_service.calculate
    @monthly_budget = @forecast_service.send(:find_monthly_budget)

    # 天気予報を取得
    weather_service = WeatherService.new
    @weather_forecast = weather_service.fetch_weekly_forecast
  end
end
