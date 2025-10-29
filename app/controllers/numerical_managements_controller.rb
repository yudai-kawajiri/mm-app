# app/controllers/numerical_managements_controller.rb
class NumericalManagementsController < ApplicationController
  before_action :authenticate_user!

  def index
    # パラメータから年月を取得、なければ当月
    if params[:target_month].present?
      @target_date = Date.parse(params[:target_month] + "-01")
    else
      @target_date = Date.today.beginning_of_month
    end

    # 月次予算を取得（なければ初期化）
    @monthly_budget = MonthlyBudget.find_or_initialize_by(
      user: current_user,
      budget_month: @target_date
    )

    # 予測データを取得
    forecast_service = NumericalForecastService.new(current_user, @target_date.year, @target_date.month)
    @forecast_data = forecast_service.calculate

    # 日別データを取得
    daily_service = DailyDataService.new(current_user, @target_date.year, @target_date.month)
    @daily_data = daily_service.call
  end
end
