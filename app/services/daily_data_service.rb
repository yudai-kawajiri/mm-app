# app/services/daily_data_service.rb
class DailyDataService
  attr_reader :user, :year, :month

  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_budget
  end

  # 日別データの配列を返す
  def call
    return [] unless @budget

    # 月の全日付を取得
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    (start_date..end_date).map do |date|
      calculate_daily_data(date)
    end
  end

  private

  def find_budget
    budget_month = Date.new(@year, @month, 1)
    MonthlyBudget.find_by(
      user: @user,
      budget_month: budget_month
    )
  end

  def calculate_daily_data(date)
    target = daily_target(date)
    actual = daily_actual(date)
    plan = daily_plan(date)
    forecast = actual > 0 ? actual : plan
    diff = forecast - target
    achievement_rate = target > 0 ? (forecast / target * 100).round(1) : 0

    {
      date: date,
      target: target,
      actual: actual,
      plan: plan,
      forecast: forecast,
      diff: diff,
      achievement_rate: achievement_rate
    }
  end

  def daily_target(date)
    daily_target_record = @budget.daily_targets.find_by(target_date: date)
    daily_target_record&.target_amount || 0
  end

  def daily_actual(date)
    # PlanScheduleから実績売上を取得
    @budget.plan_schedules
           .where(scheduled_date: date)
           .where.not(actual_revenue: nil)
           .sum(:actual_revenue)
  end

  def daily_plan(date)
    # PlanScheduleから計画売上を取得（実績未入力のもの）
    # 現時点では0を返す（expected_revenueカラムがないため）
    0
  end
end
