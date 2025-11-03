class NumericalForecastService
  attr_reader :user, :year, :month, :budget

  def initialize(user:, year:, month:)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_budget
    @today = Date.current
  end

  def calculate
    actual = actual_amount
    planned = planned_amount
    forecast = actual + planned
    target = target_amount
    diff = forecast - target

    {
      target_amount: target,
      actual_amount: actual,
      planned_amount: planned_amount,
      forecast_amount: forecast,
      daily_achievement_rate: daily_achievement_rate,

      forecast_achievement_rate: target > 0 ? (forecast / target * 100).round(1) : 0,
      forecast_diff: diff,

      remaining_days: remaining_days,
      required_additional: diff < 0 ? diff.abs : 0,
      daily_required: remaining_days > 0 && diff < 0 ? (diff.abs / remaining_days).round(0) : 0
    }
  end

  private

  def find_budget
    budget_month = Date.new(@year, @month, 1)
    MonthlyBudget.find_by(
      user: @user,
      budget_month: budget_month
    )
  end

  def target_amount
    @budget&.target_amount || 0
  end

  # 月全体の実績売上
  def actual_amount
    return 0 unless @budget

    PlanSchedule.joins(:plan)
                .where(plans: { user_id: @user.id })
                .where("DATE_TRUNC('month', scheduled_date) = ?", Date.new(@year, @month, 1))
                .where.not(actual_revenue: nil)
                .where("actual_revenue > 0")
                .sum(:actual_revenue) || 0
  end

  # 指定日までの実績売上（日次予算達成率の計算用）
  def actual_amount_until(date)
    return 0 unless @budget

    PlanSchedule.joins(:plan)
                .where(plans: { user_id: @user.id })
                .where("scheduled_date >= ? AND scheduled_date <= ?", Date.new(@year, @month, 1), date)
                .where.not(actual_revenue: nil)
                .where("actual_revenue > 0")
                .sum(:actual_revenue) || 0
  end

  def planned_amount
    return 0 unless @budget

    schedules_without_actual = PlanSchedule.joins(:plan)
                                           .where(plans: { user_id: @user.id })
                                           .where("DATE_TRUNC('month', scheduled_date) = ?", Date.new(@year, @month, 1))
                                           .where("actual_revenue IS NULL OR actual_revenue = 0")
                                           .includes(plan: { plan_products: :product })

    schedules_without_actual.sum do |schedule|
      schedule.plan.plan_products.sum do |pp|
        pp.product.price * pp.production_count
      end
    end
  end

  def remaining_days
    first_day = Date.new(@year, @month, 1)
    last_day = Date.new(@year, @month, -1)

    return 0 if @today > last_day
    return last_day.day if @today < first_day

    (last_day - @today).to_i + 1
  end

  # 日次予算達成率（昨日までの予算に対する昨日までの実績の割合）
  def daily_achievement_rate
    return 0 if target_amount == 0

    first_day = Date.new(@year, @month, 1)
    last_day = Date.new(@year, @month, -1)
    yesterday = @today - 1.day

    return 0 if @today < first_day

    # 対象月が過去の場合（月末までの達成率）
    if @today > last_day
      return target_amount > 0 ? (actual_amount.to_f / target_amount * 100).round(1) : 0
    end

    # 昨日までの経過日数
    days_passed = [(yesterday - first_day).to_i, 0].max + 1
    days_in_month = last_day.day

    # 昨日までの日割り予算
    budget_until_yesterday = (target_amount.to_f / days_in_month * days_passed).round

    # 昨日までの実績
    actual_until_yesterday = actual_amount_until(yesterday)


    # 昨日までの予算達成率
    budget_until_yesterday > 0 ? (actual_until_yesterday.to_f / budget_until_yesterday * 100).round(1) : 0
  end
end