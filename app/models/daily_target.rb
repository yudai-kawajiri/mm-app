class DailyTarget < ApplicationRecord
  # 関連付け
  belongs_to :user
  belongs_to :monthly_budget

  # バリデーション
  validates :target_date, presence: true, uniqueness: { scope: :monthly_budget_id }
  validates :target_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # スコープ
  # 指定された年月の日別目標を取得
  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(target_date: start_date..end_date)
  }

  # 日付順で取得（降順）
  scope :recent, -> { order(target_date: :desc) }
end
