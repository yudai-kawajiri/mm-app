# app/services/daily_data_service.rb
class DailyDataService
  attr_reader :user, :year, :month

  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_budget
    load_data_for_month  # ← 追加
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

  # ★★★ 追加: データ事前ロード ★★★
  def load_data_for_month
    return unless @budget

    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    # 日別目標を事前ロード
    @daily_targets = @budget.daily_targets
                            .where(target_date: start_date..end_date)
                            .to_a

    # 計画スケジュールを事前ロード（ユーザーの全計画）
    @plan_schedules = @user.plan_schedules
                           .where(scheduled_date: start_date..end_date)
                           .includes(:plan)
                           .to_a
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

  # ★★★ 修正: メモリ上検索に変更 ★★★
  def daily_target(date)
    daily_targets = @daily_targets || []
    daily_target = daily_targets.find { |dt| dt.target_date == date }
    daily_target&.target_amount || 0
  end

  # ★★★ 修正: メモリ上検索 + nil安全処理 ★★★
  def daily_actual(date)
    plan_schedules_list = @plan_schedules || []
    plan_schedules = plan_schedules_list.select { |ps| ps.scheduled_date == date }
    plan_schedules.sum { |ps| ps.actual_revenue || 0 }
  end

  # 修正: メモリ上検索 + nil安全処理
  def daily_plan(date)
    plan_schedules_list = @plan_schedules || []
    plan_schedules = plan_schedules_list.select { |ps| ps.scheduled_date == date }
    plan_schedules.sum { |ps| ps.planned_revenue || 0 }
  end
end
