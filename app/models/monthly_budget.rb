class MonthlyBudget < ApplicationRecord
  # 関連付け
  belongs_to :user

  # バリデーション
  # 対象月
  validates :budget_month, presence: true, uniqueness: { scope: :user_id }
  # 目標金額
  validates :target_amount, presence: true, numericality: { greater_than: 0 }

  # スコープ
  # 指定された年月の予算を取得（月初のデータのみを参照）
  scope :for_month, ->(year, month) { where(budget_month: Date.new(year, month, 1)) }
  # 予算対象月の降順で取得
  scope :recent, -> { order(budget_month: :desc) }

  # コールバック
  # バリデーション前に budget_month を月の初日（1日）に正規化する
  before_validation :normalize_budget_month

  # 属性ヘルパーメソッド
  # budget_month から年を取得
  def year
    budget_month.year
  end

  # budget_month から月を取得
  def month
    budget_month.month
  end

  # 関連する PlanSchedule の取得
  # 当該予算月に紐づく、現在のユーザーのすべての PlanSchedule を取得
  def plan_schedules
    start_date = budget_month.beginning_of_month
    end_date = budget_month.end_of_month
    PlanSchedule.joins(:plan)
                 .where(plans: { user_id: user.id })
                 .where(scheduled_date: start_date..end_date)
  end

  # 集計メソッド

  # 月の合計予定売上を計算
  def total_planned_revenue
    plan_schedules.sum { |ps| ps.expected_revenue }
  end

  # 月の合計実績売上を計算
  def total_actual_revenue
    plan_schedules.where.not(actual_revenue: nil).sum(:actual_revenue)
  end

  # 月の総見込み売上を計算 (実績売上 + 残りの予定売上)
  def total_forecast_revenue
    total_actual_revenue + remaining_planned_revenue
  end

  # 残りの予定売上を計算（今日以降の予定売上、または今日で実績が未入力の予定売上）
  def remaining_planned_revenue
    today = Date.current
    plan_schedules.where('scheduled_date > ?', today)
                  .sum { |ps| ps.expected_revenue } +
    plan_schedules.where(scheduled_date: today, actual_revenue: nil)
                  .sum { |ps| ps.expected_revenue }
  end

  # 業績評価メソッド

  # 達成率を計算 (見込み売上 / 目標金額 * 100)
  def achievement_rate
    return 0 if target_amount.zero?
    (total_forecast_revenue / target_amount * 100).round(1)
  end

  # 予算差異を計算 (見込み売上 - 目標金額)
  def budget_variance
    total_forecast_revenue - target_amount
  end

  # プライベートメソッド

  private

  # 入力された budget_month を常にその月の1日（月初）に設定する
  def normalize_budget_month
    self.budget_month = budget_month.beginning_of_month if budget_month.present?
  end
end