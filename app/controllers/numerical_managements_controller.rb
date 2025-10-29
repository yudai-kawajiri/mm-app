class NumericalManagementsController < ApplicationController
  def index
    # 月選択パラメータの取得（monthまたはtarget_monthに対応）
    month_param = params[:month] || params[:target_month] || Date.today.strftime('%Y-%m')
    @selected_date = Date.parse("#{month_param}-01")

    # MonthlyBudgetを取得
    @budget = MonthlyBudget.find_by(budget_month: @selected_date.beginning_of_month)

    unless @budget
      # 予算が未設定の場合の処理
      @forecast_data = {
        target_amount: 0,
        actual_amount: 0,
        planned_amount: 0,
        forecast_amount: 0,
        remaining_days: 0,
        achievement_rate: 0,
        required_additional: 0,
        daily_required: 0,
        forecast_diff: 0
      }
      @daily_data = []
      return
    end

    def calendar
      # 月選択パラメータの取得
      month_param = params[:month] || Date.today.strftime('%Y-%m')
      @selected_date = Date.parse("#{month_param}-01")

      # MonthlyBudgetを取得
      @budget = MonthlyBudget.find_by(
      user: current_user,
      budget_month: @selected_date.beginning_of_month
    )

      # カレンダーデータを取得
      calendar_service = CalendarDataService.new(current_user, @selected_date.year, @selected_date.month)
      @calendar_data = calendar_service.call
    end


    # 予測データを取得
    forecast_service = NumericalForecastService.new(current_user, @selected_date.year, @selected_date.month)
    @forecast_data = forecast_service.calculate

    # 日別データを取得
    daily_service = DailyDataService.new(current_user, @selected_date.year, @selected_date.month)
    @daily_data = daily_service.call  # ← calculate から call に変更
  end
end
