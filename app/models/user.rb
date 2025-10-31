class User < ApplicationRecord
  has_many :categories, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :materials, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :monthly_budgets, dependent: :destroy
  has_many :plan_schedules, dependent: :destroy
  has_many :daily_targets, dependent: :destroy

  # Deviseの認証モジュールを設定
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable

  # 名前（name）は登録時のみ必要
  validates :name, presence: true
  validates :name, length: { maximum: 50 }

  # 指定月の予算を取得
  def budget_for_month(date)
    date = date.beginning_of_month if date.is_a?(Date) || date.is_a?(Time)
    monthly_budgets.where(budget_month: date).first
  end
end
