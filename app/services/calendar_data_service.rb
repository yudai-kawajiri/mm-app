class CalendarDataService
  attr_reader :user, :year, :month

  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_budget
    load_data_for_month
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
    # @daily_targetsがnilの場合は空配列として扱う
    daily_targets = @daily_targets || []
    plan_schedules_list = @plan_schedules || []

    daily_target = daily_targets.find { |dt| dt.target_date == date }
    plan_schedules = plan_schedules_list.select { |ps| ps.scheduled_date == date }

    target_amount = daily_target&.target_amount || 0

    actual_revenue = plan_schedules.sum { |ps| ps.actual_revenue || 0 }
    planned_revenue = plan_schedules.sum { |ps| ps.planned_revenue || 0 }

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
      plan: planned_revenue,
      plan_schedules: plan_schedules,
      plan_schedule_id: plan_schedules.first&.id,
      is_today: date == Date.today,
      achievement_rate: achievement_rate
    }
  end

  def load_data_for_month
    return unless @budget

    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    # 日別目標を事前ロード
    @daily_targets = @budget.daily_targets
                            .where(target_date: start_date..end_date)
                            .to_a

    # 計画スケジュールを事前ロード（ユーザーの全計画、カテゴリも含む）
    @plan_schedules = @user.plan_schedules
                          .where(scheduled_date: start_date..end_date)
                          .includes(plan: :category)
                          .to_a
  end
end
