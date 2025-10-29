# 日別データ集計サービス
# 日付ごとの予算、計画、実績、差額を計算
class DailyDataService
  attr_reader :user, :year, :month

  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_budget
  end

  # 日別データを生成
  def generate
    return [] unless @budget

    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month
    
    daily_data = []
    cumulative_target = 0
    cumulative_actual = 0

    (start_date..end_date).each do |date|
      # 日別目標
      target = daily_target_for(date)
      
      # 日別計画
      planned = planned_amount_for(date)
      
      # 日別実績
      actual = actual_amount_for(date)
      
      # 累計計算
      cumulative_target += target
      cumulative_actual += actual
      
      # 差額計算
      daily_difference = actual - target
      cumulative_difference = cumulative_actual - cumulative_target
      
      # 達成率
      rate = cumulative_target.zero? ? 0 : ((cumulative_actual / cumulative_target) * 100).round(2)

      daily_data << {
        date: date,
        day_of_week: I18n.t("date.abbr_day_names")[date.wday],
        target: target,
        planned: planned,
        actual: actual,
        daily_difference: daily_difference,
        cumulative_actual: cumulative_actual,
        cumulative_difference: cumulative_difference,
        achievement_rate: rate
      }
    end

    daily_data
  end

  private

  def find_budget
    budget_month = Date.new(@year, @month, 1)
    MonthlyBudget.find_by(user: @user, budget_month: budget_month)
  end

  # 日別目標金額
  def daily_target_for(date)
    return 0 unless @budget
    
    # daily_targetsテーブルから取得
    daily_target = DailyTarget.find_by(
      monthly_budget_id: @budget.id,
      target_date: date
    )
    
    if daily_target
      daily_target.target_amount
    else
      # なければ均等配分
      days_in_month = Date.new(@year, @month, -1).day
      (@budget.target_amount / days_in_month).round(2)
    end
  end

  # 日別計画売上
  def planned_amount_for(date)
    schedules = PlanSchedule.joins(:plan)
                            .where(plans: { user_id: @user.id })
                            .where(scheduled_date: date)
                            .includes(plan: { plan_products: :product })

    schedules.sum do |schedule|
      schedule.plan.plan_products.sum do |pp|
        pp.product.price * pp.production_count
      end
    end
  end

  # 日別実績売上
  def actual_amount_for(date)
    PlanSchedule.joins(:plan)
                .where(plans: { user_id: @user.id })
                .where(scheduled_date: date)
                .where(status: :completed)
                .sum(:actual_revenue) || 0
  end
end
