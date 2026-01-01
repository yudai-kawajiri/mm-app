# frozen_string_literal: true

class User < ApplicationRecord
  NAME_MAX_LENGTH = 50
  RANDOM_PASSWORD_LENGTH = 12
  PHONE_DIGIT_RANGE = (10..11).freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :company
  belongs_to :store, optional: true

  has_many :admin_requests, dependent: :destroy
  has_many :approved_requests, class_name: "AdminRequest", foreign_key: :approved_by_id
  has_many :categories, class_name: "Resources::Category", foreign_key: :user_id, dependent: :nullify

  enum :role, {
    general: 0,
    store_admin: 1,
    company_admin: 2,
    super_admin: 3
  }

  attr_accessor :invitation_code

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :phone,
            format: { with: /\A\d{10,11}\z/, message: :invalid_phone_format },
            allow_blank: true
  validate :invitation_code_valid, on: :create
  validate :store_required_for_store_admin

  before_validation :normalize_phone
  before_validation :generate_random_password, on: :create, if: -> { password.blank? }

  module AuthenticationControl
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

  def monthly_budget(date)
    company.monthly_budgets.for_month(date.year, date.month).first
  end

  def can_manage_company?
    company_admin? || super_admin?
  end

  def can_manage_store?(target_store)
    return true if super_admin?
    return true if company_admin? && target_store.company_id == company_id
    store_admin? && store_id == target_store.id
  end

  def accessible_companies
    super_admin? ? Company.all : Company.where(id: company_id)
  end

  def accessible_stores
    can_manage_company? ? company.stores : Store.where(id: store_id)
  end

  private

  def generate_random_password
    self.password = SecureRandom.alphanumeric(RANDOM_PASSWORD_LENGTH)
    self.password_confirmation = password
  end

  def normalize_phone
    return if phone.blank?

    self.phone = phone.gsub(/[-\s()]/, "")
    self.phone = nil unless phone.match?(/\A\d{#{PHONE_DIGIT_RANGE.min},#{PHONE_DIGIT_RANGE.max}}\z/)
  end

  def invitation_code_valid
    return if invitation_code.blank? || store_id.blank?

    store = Store.find_by(id: store_id)
    errors.add(:invitation_code, :invalid) unless store&.invitation_code == invitation_code
  end

  def store_required_for_store_admin
    errors.add(:store_id, :blank) if store_admin? && store_id.blank?
  end

def self.roles_i18n_custom
  {
    general: I18n.t("activerecord.attributes.user.roles.general"),
    store_admin: I18n.t("activerecord.attributes.user.roles.store_admin"),
    company_admin: I18n.t("activerecord.attributes.user.roles.company_admin"),
    super_admin: I18n.t("activerecord.attributes.user.roles.super_admin")
  }
end
end
