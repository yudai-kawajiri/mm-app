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
  # 名前の最大文字数
  NAME_MAX_LENGTH = 50

  # Deviseの認証モジュールを設定
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable

  enum :role, {
  general: 0,
  store_admin: 1,
  company_admin: 2,
  super_admin: 3
}

  # 招待コード用の仮想属性
  attr_accessor :invitation_code

  # バリデーション
  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validate :invitation_code_valid, on: :create

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

  # 招待コードのバリデーション
  def invitation_code_valid
    return if invitation_code&.strip == ENV['INVITATION_CODE']

    errors.add(:invitation_code, :invalid)
  end
end
