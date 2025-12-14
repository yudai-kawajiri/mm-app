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

  # マルチテナント対応: 会社とストアへの所属
  belongs_to :tenant
  belongs_to :store, optional: true  # 会社管理者はストア未所属の場合あり

  # AdminRequest関連
  has_many :admin_requests, dependent: :destroy
  has_many :approved_requests, class_name: 'AdminRequest', foreign_key: :approved_by_id

  # 4段階の権限管理
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

  # 初期化時のデフォルト値
  after_initialize :set_default_role, if: :new_record?

  # 月次予算を取得
  def budget_for_month(date)
    MonthlyBudget.for_month(date).first
  end

  # 権限チェック
  def can_manage_company?
    company_admin? || super_admin?
  end

  def can_manage_store?(target_store)
    return true if super_admin?
    return true if company_admin? && target_store.tenant_id == tenant_id
    store_admin? && store_id == target_store.id
  end

  # アクセス可能なテナント
  def accessible_tenants
    super_admin? ? Tenant.all : Tenant.where(id: tenant_id)
  end

  # アクセス可能なストア
  def accessible_stores
    return tenant.stores if company_admin? || super_admin?
    Store.where(id: store_id)
  end

  # Devise: 未承認ユーザーのログイン制御
  # Deviseのメソッドを確実にオーバーライドするため、モジュールを定義して prepend
  module AuthenticationControl
    def active_for_authentication?
      approved?
    end

    def inactive_message
      approved? ? super : :not_approved
    end
  end

  prepend AuthenticationControl

  private

  def set_default_role
    self.role ||= :general
  end

  def invitation_code_valid
    return if invitation_code.blank?

    valid_code = Rails.application.credentials.dig(:invitation_code)
    errors.add(:invitation_code, :invalid) if invitation_code != valid_code
  end
end
