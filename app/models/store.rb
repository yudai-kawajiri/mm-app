# frozen_string_literal: true

class Store < ApplicationRecord
  INVITATION_CODE_LENGTH = 8
  MAX_CODE_GENERATION_ATTEMPTS = 100

  attribute :active, :boolean, default: true

  belongs_to :company

  has_many :users, dependent: :restrict_with_error
  has_many :products, class_name: "Resources::Product", dependent: :destroy
  has_many :materials, class_name: "Resources::Material", dependent: :destroy
  has_many :categories, class_name: "Resources::Category", dependent: :destroy
  has_many :plans, class_name: "Resources::Plan", dependent: :destroy
  has_many :material_order_groups, class_name: "Resources::MaterialOrderGroup", dependent: :destroy
  has_many :daily_targets, class_name: "Management::DailyTarget", dependent: :destroy
  has_many :monthly_budgets, class_name: "Management::MonthlyBudget", dependent: :destroy
  has_many :plan_schedules, class_name: "Planning::PlanSchedule", dependent: :destroy
  has_many :units, class_name: "Resources::Unit", dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :invitation_code, uniqueness: true, allow_nil: true

  before_create :generate_invitation_code

  def regenerate_invitation_code!
    generate_unique_invitation_code
    save!
  end

  private

  def generate_invitation_code
    return if invitation_code.present?
    generate_unique_invitation_code
  end

  def generate_unique_invitation_code
    MAX_CODE_GENERATION_ATTEMPTS.times do
      self.invitation_code = SecureRandom.alphanumeric(INVITATION_CODE_LENGTH).upcase
      return unless Store.exists?(invitation_code: invitation_code)
    end

    raise "Failed to generate unique invitation code after #{MAX_CODE_GENERATION_ATTEMPTS} attempts"
  end
end
