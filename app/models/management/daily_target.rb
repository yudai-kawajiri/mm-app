# frozen_string_literal: true

# 日別目標（月次予算を日単位に分割）
class Management::DailyTarget < ApplicationRecord
  belongs_to :company
  belongs_to :monthly_budget, class_name: "Management::MonthlyBudget"

  has_paper_trail
  include UserAssociatable

  validates :target_date, presence: true, uniqueness: { scope: :monthly_budget_id }
  validates :target_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_company_id, on: :create

  scope :for_month, ->(year, month) { where(target_date: Date.new(year, month, 1).all_month) }
  scope :recent, -> { order(target_date: :desc) }

  # 当日の実績売上を取得
  def actual_revenue
    @actual_revenue ||= Planning::PlanSchedule
                        .where(scheduled_date: target_date, company_id: company_id)
                        .sum(:actual_revenue)
  end

  # 達成率を計算
  def achievement_rate
    return 0 if target_amount.zero?
    (actual_revenue.to_f / target_amount * 100).round(1)
  end

  private

  def set_company_id
    self.company_id ||= monthly_budget&.company_id
  end
end
