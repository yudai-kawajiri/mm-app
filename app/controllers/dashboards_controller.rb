# frozen_string_literal: true

class DashboardsController < AuthenticatedController
  def index
    @show_welcome_modal = session.delete(:first_login)

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
  end
end
