# frozen_string_literal: true

# User
#
# ユーザーモデル - 認証とリソース所有を管理
#
# 使用例:
#   User.create(email: "user@example.com", password: "password", name: "山田太郎")
#   user.budget_for_month(Date.today)
#   user.admin?
class User < ApplicationRecord
  # Deviseの認証モジュールを設定
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable

  # ロール管理
  enum :role, { staff: 0, admin: 1 }

  # 関連付け
  has_many :categories, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :materials, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :monthly_budgets, dependent: :destroy
  has_many :plan_schedules, dependent: :destroy
  has_many :daily_targets, dependent: :destroy
  has_many :material_order_groups, dependent: :destroy

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }

  # 新規ユーザーのデフォルトロールをstaffに設定
  after_initialize :set_default_role, if: :new_record?

  # 指定月の予算を取得
  #
  # @param date [Date, Time] 対象月の日付
  # @return [MonthlyBudget, nil] 月次予算
  def budget_for_month(date)
    date = date.beginning_of_month if date.is_a?(Date) || date.is_a?(Time)
    monthly_budgets.find_by(budget_month: date)
  end

  private

  # デフォルトロールを設定
  def set_default_role
    self.role ||= :staff
  end
end
