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

  # 実績売上（実績入力済みの計画の実績合計）
  def actual_amount
    return 0 unless @budget

    # 実績が入力済みの計画の実績合計
    PlanSchedule.joins(:plan)
                .where(plans: { user_id: @user.id })
                .where("DATE_TRUNC('month', scheduled_date) = ?", Date.new(@year, @month, 1))
                .where.not(actual_revenue: nil)
                .where("actual_revenue > 0")
                .sum(:actual_revenue) || 0
  end

  # 計画売上（実績未入力の計画の計画高合計）
  def planned_amount
    return 0 unless @budget

    # 実績が未入力の計画のみを計算
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

  # 残り日数（対象月内のみ、月をまたぐ場合は適切な値）
  def remaining_days
    first_day = Date.new(@year, @month, 1)
    last_day = Date.new(@year, @month, -1)

    # 対象月が過去の場合（0）
    return 0 if @today > last_day

    # 対象月が未来の場合（月の総日数）
    return last_day.day if @today < first_day

    # 対象月が現在進行中（今日から月末まで）
    (last_day - @today).to_i + 1
  end
end