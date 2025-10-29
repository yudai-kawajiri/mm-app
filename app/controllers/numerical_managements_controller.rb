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
    service = NumericalForecastService.new(current_user, @target_date.year, @target_date.month)
    forecast_result = service.calculate

    # ビューで使いやすい形式に変換
    @forecast_data = {
      target_total: forecast_result[:target_amount] || 0,
      actual_total: forecast_result[:actual_amount] || 0,
      plan_total: forecast_result[:planned_amount] || 0,
      forecast_total: (forecast_result[:actual_amount] || 0) + (forecast_result[:planned_amount] || 0)
    }
  end
end
