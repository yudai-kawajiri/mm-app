# frozen_string_literal: true

class Management::MonthlyBudget < ApplicationRecord
  belongs_to :company
  has_paper_trail

  include UserAssociatable

  has_many :daily_targets, dependent: :destroy

  # フォーム定数
  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3
  ACHIEVEMENT_RATE_DECIMAL_PLACES = 1

  # バリデーション
  validates :budget_month, presence: true, uniqueness: { scope: :store_id }
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  # 指定された年月の予算を取得
  scope :for_month, ->(year, month) { where(budget_month: Date.new(year, month, 1)) }
  scope :recent, -> { order(budget_month: :desc) }
  scope :for_year, lambda { |year|
    where(budget_month: Date.new(year, 1, 1)..Date.new(year, 12, 31))
  }

  before_validation :normalize_budget_month

  def year
    budget_month.year
  end

  def month
    budget_month.month
  end

  # 当該月の計画スケジュール（会社スコープ付き）
  def plan_schedules
    @plan_schedules ||= Planning::PlanSchedule
                        .joins(:plan)
                        .where(company_id: company_id)
                        .where(scheduled_date: budget_month.all_month)
  end

  def total_planned_revenue
    plan_schedules.sum('COALESCE(expected_revenue, 0)')
  end

  def total_actual_revenue
    plan_schedules.sum('COALESCE(actual_revenue, 0)')
  end

  # 総見込み売上（実績 + 残り予定）
  def total_forecast_revenue
    total_actual_revenue + remaining_planned_revenue
  end

  # 今日以降の予定売上（実績未入力分のみ）
  def remaining_planned_revenue
    today = Date.current
    plan_schedules.where('scheduled_date >= ?', today)
                  .where(actual_revenue: nil)
                  .sum('COALESCE(expected_revenue, 0)')
  end

  def achievement_rate
    return 0 if target_amount.zero?
    (total_forecast_revenue.to_f / target_amount * 100).round(ACHIEVEMENT_RATE_DECIMAL_PLACES)
  end

  def budget_variance
    total_forecast_revenue - target_amount
  end

  private

  def normalize_budget_month
    self.budget_month = budget_month.beginning_of_month if budget_month.present?
  end
end
