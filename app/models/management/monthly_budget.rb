# frozen_string_literal: true

# MonthlyBudget
#
# 月次予算モデル - 月ごとの目標金額を管理
#
# 使用例:
#   MonthlyBudget.create(budget_month: Date.new(2024, 12, 1), target_amount: 1500000)
#   MonthlyBudget.for_month(2024, 12)
#   budget.achievement_rate
class Management::MonthlyBudget < ApplicationRecord
  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include UserAssociatable

  # 日別目標との関連
  has_many :daily_targets, dependent: :destroy

  # フォーム定数
  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  # バリデーション
  validates :budget_month, presence: true, uniqueness: true
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  # 指定された年月の予算を取得(月初のデータのみを参照)
  #
  # @param year [Integer] 年
  # @param month [Integer] 月
  # @return [ActiveRecord::Relation] 検索結果
  scope :for_month, ->(year, month) { where(budget_month: Date.new(year, month, 1)) }

  # 予算対象月の降順で取得
  scope :recent, -> { order(budget_month: :desc) }

  # 指定された年の予算を取得
  #
  # @param year [Integer] 年
  # @return [ActiveRecord::Relation] 検索結果
  scope :for_year, lambda { |year|
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)
    where(budget_month: start_date..end_date)
  }

  # バリデーション前に budget_month を月の初日(1日)に正規化する
  before_validation :normalize_budget_month

  # budget_month から年を取得
  #
  # @return [Integer] 年
  def year
    budget_month.year
  end

  # budget_month から月を取得
  #
  # @return [Integer] 月
  def month
    budget_month.month
  end

  # 関連する PlanSchedule の取得
  #
  # 当該予算月に紐づく、現在のユーザーのすべての PlanSchedule を取得
  #
  # @return [ActiveRecord::Relation] PlanScheduleの配列
  def plan_schedules
    start_date = budget_month.beginning_of_month
    end_date = budget_month.end_of_month
    Planning::PlanSchedule.joins(:plan)
                          .where(scheduled_date: start_date..end_date)
  end

  # 月の合計予定売上を計算
  #
  # @return [Integer] 合計予定売上
  def total_planned_revenue
    plan_schedules.sum(&:expected_revenue)
  end

  # 月の合計実績売上を計算
  #
  # @return [Integer] 合計実績売上
  def total_actual_revenue
    plan_schedules.where.not(actual_revenue: nil).sum(:actual_revenue)
  end

  # 月の総見込み売上を計算(実績売上 + 残りの予定売上)
  #
  # @return [Integer] 総見込み売上
  def total_forecast_revenue
    total_actual_revenue + remaining_planned_revenue
  end

  # 残りの予定売上を計算(今日以降の予定売上、または今日で実績が未入力の予定売上)
  #
  # @return [Integer] 残りの予定売上
  def remaining_planned_revenue
    today = Date.current
    plan_schedules.where("scheduled_date > ?", today)
                  .sum(&:expected_revenue) +
      plan_schedules.where(scheduled_date: today, actual_revenue: nil)
                    .sum(&:expected_revenue)
  end

  # 達成率を計算(見込み売上 / 目標金額 * 100)
  #
  # @return [Float] 達成率(%)
  def achievement_rate
    return 0 if target_amount.zero?

    (total_forecast_revenue.to_f / target_amount * 100).round(1)
  end

  # 予算差異を計算(見込み売上 - 目標金額)
  #
  # @return [Integer] 予算差異
  def budget_variance
    total_forecast_revenue - target_amount
  end

  private

  # 入力された budget_month を常にその月の1日(月初)に設定する
  def normalize_budget_month
    self.budget_month = budget_month.beginning_of_month if budget_month.present?
  end
end
