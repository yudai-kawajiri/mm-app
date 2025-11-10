# frozen_string_literal: true

# DailyTarget
#
# 日別目標モデル - 月次予算の日ごとの目標金額を管理
#
# 使用例:
#   DailyTarget.create(target_date: Date.today, target_amount: 50000, monthly_budget_id: 1)
#   DailyTarget.for_month(2024, 12)
#   DailyTarget.recent
class Management::DailyTarget < ApplicationRecord

  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include UserAssociatable

  # 月次予算との関連
  belongs_to :monthly_budget, class_name: 'Management::MonthlyBudget'

  # バリデーション
  validates :target_date, presence: true, uniqueness: { scope: :monthly_budget_id }
  validates :target_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # 指定された年月の日別目標を取得
  #
  # @param year [Integer] 年
  # @param month [Integer] 月
  # @return [ActiveRecord::Relation] 検索結果
  scope :for_month, lambda { |year, month|
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(target_date: start_date..end_date)
  }

  # 日付順で取得（降順）
  scope :recent, -> { order(target_date: :desc) }
end
