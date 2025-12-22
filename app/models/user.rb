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
  belongs_to :company
  belongs_to :store, optional: true  # 会社管理者はストア未所属の場合あり

  # AdminRequest関連
  has_many :admin_requests, dependent: :destroy
  has_many :approved_requests, class_name: "AdminRequest", foreign_key: :approved_by_id

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
  validates :phone, format: { with: /\A\d{10,11}\z/, message: :invalid_phone_format }, allow_blank: true
  validate :invitation_code_valid, on: :create
  validate :store_required_for_store_admin

  # Callbacks
  before_validation :normalize_phone
  before_validation :generate_random_password, on: :create, if: -> { password.blank? }

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
    return true if company_admin? && target_store.company_id == company_id
    store_admin? && store_id == target_store.id
  end

  # アクセス可能なテナント
  def accessible_companies
    super_admin? ? Company.all : Company.where(id: company_id)
  end

  # アクセス可能なストア
  def accessible_stores
    return company.stores if company_admin? || super_admin?
    Store.where(id: store_id)
  end

  # Devise: 未承認ユーザーのログイン制御
  module AuthenticationControl
  # 承認システムを無効化
  def approved?
    true
  end

    def active_for_authentication?
      approved?
    end

    def inactive_message
      approved? ? super : :not_approved
    end
  end

  prepend AuthenticationControl

  private

  def generate_random_password
    self.password = SecureRandom.alphanumeric(12)
    self.password_confirmation = self.password
  end

  def normalize_phone
    self.phone = phone.gsub(/[-\s()]/, "") if phone.present?
  end


  def invitation_code_valid
    return if invitation_code.blank?
    return unless store_id.present?

    store = Store.find_by(id: store_id)
    unless store && store.invitation_code == invitation_code
      errors.add(:invitation_code, :invalid)
    end
  end

  def store_required_for_store_admin
    if store_admin? && store_id.blank?
      errors.add(:store_id, :blank)
    end
  end

  # 管理者作成ユーザーは自動承認
end

  # 承認システムを無効化（管理者作成ユーザーは即座にログイン可能）
  def approved?
    true
  end

  # 権限の日本語表示用
  def self.roles_i18n
    {
      I18n.t('admin.users.roles.general') => 'general',
      I18n.t('admin.users.roles.store_admin') => 'store_admin',
      I18n.t('admin.users.roles.company_admin') => 'company_admin',
      I18n.t('admin.users.roles.super_admin') => 'super_admin'
    }
  end
