# app/services/calendar_data_service.rb
class CalendarDataService
  attr_reader :user, :year, :month

  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_budget
  end

  # カレンダー表示用のデータを返す
  def call
    return [] unless @budget

    # 月の全日付を取得
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    # 週ごとにグループ化
    weeks = []
    current_week = []

    # 月初の曜日まで空白セルを追加
    start_date.wday.times do
      current_week << nil
    end

    # 各日のデータを追加
    (start_date..end_date).each do |date|
      current_week << build_day_data(date)

      # 土曜日（wday == 6）で週を区切る
      if date.wday == 6
        weeks << current_week
        current_week = []
      end
    end

    # 最後の週が未完成なら追加
    weeks << current_week unless current_week.empty?

    weeks
  end

  private

  def find_budget
    budget_month = Date.new(@year, @month, 1)
    MonthlyBudget.find_by(
      user: @user,
      budget_month: budget_month
    )
  end


  def build_day_data(date)
    daily_target = @daily_targets.find { |dt| dt.target_date == date }
    plan_schedules = @plan_schedules.select { |ps| ps.scheduled_date == date }

    target_amount = daily_target&.target_amount || 0
    actual_revenue = plan_schedules.sum(&:actual_revenue)

    # 達成率計算（ゼロ除算対策）
    achievement_rate = if target_amount > 0
                        ((actual_revenue.to_f / target_amount) * 100).round(1)
                      else
                        nil
                      end

    {
      date: date,
      target: target_amount,
      daily_target_id: daily_target&.id,
      actual: actual_revenue,
      plan: plan_schedules.sum(&:planned_revenue),
      plan_schedules: plan_schedules,
      plan_schedule_id: plan_schedules.first&.id,
      is_today: date == Date.today,
      achievement_rate: achievement_rate
    }
  end


  def daily_target(date)
    daily_target_record = @budget.daily_targets.find_by(target_date: date)
    daily_target_record&.target_amount || 0
  end

  def daily_actual(date)
    @budget.plan_schedules
           .where(scheduled_date: date)
           .where.not(actual_revenue: nil)
           .sum(:actual_revenue)
  end

  def daily_plan(date)
    @budget.plan_schedules
          .where(scheduled_date: date)
          .where.not(planned_revenue: nil)
          .sum(:planned_revenue)
  end

end
