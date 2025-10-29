# app/services/numerical_forecast_service.rb
class NumericalForecastService
  attr_reader :user, :year, :month, :budget

  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_budget
    @today = Date.current
  end

  # 全ての予測データを計算
  def calculate
    actual = actual_amount
    planned = planned_amount
    forecast = actual + planned
    target = target_amount
    diff = forecast - target

    {
      # サマリー
      target_amount: target,
      actual_amount: actual,
      planned_amount: planned,
      forecast_amount: forecast,

      # 月末予測グループ
      achievement_rate: target > 0 ? (forecast / target * 100).round(1) : 0,
      forecast_diff: diff,

      # ギャップ分析グループ
      remaining_days: remaining_days,
      required_additional: diff < 0 ? diff.abs : 0,
      daily_required: remaining_days > 0 && diff < 0 ? (diff.abs / remaining_days).round(0) : 0
    }
  end

  private

  # 予算を取得（なければnil）
  def find_budget
    budget_month = Date.new(@year, @month, 1)
    MonthlyBudget.find_by(
      user: @user,
      budget_month: budget_month
    )
  end

  # 目標金額
  def target_amount
    @budget&.target_amount || 0
  end

  # 実績売上
  def actual_amount
    return 0 unless @budget
    @budget.total_actual_revenue
  end

  # 計画売上
  def planned_amount
    return 0 unless @budget
    @budget.remaining_planned_revenue
  end

  # 残り日数
  def remaining_days
    last_day = Date.new(@year, @month, -1)
    return 0 if @today > last_day
    (last_day - @today).to_i + 1
  end
end
