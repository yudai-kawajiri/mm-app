# frozen_string_literal: true

# Store
#
# 店舗モデル
# - 1つの会社（Tenant）に複数の店舗が所属
# - データは店舗ごとに完全分離（他店舗のデータは閲覧不可）
class Store < ApplicationRecord
  belongs_to :tenant
  has_many :users, dependent: :nullify
  has_many :products, class_name: 'Resources::Product', dependent: :nullify
  has_many :materials, class_name: 'Resources::Material', dependent: :nullify
  has_many :categories, class_name: 'Resources::Category', dependent: :nullify
  has_many :plans, class_name: 'Resources::Plan', dependent: :nullify
  has_many :material_order_groups, class_name: 'Resources::MaterialOrderGroup', dependent: :nullify
  has_many :daily_targets, class_name: 'Management::DailyTarget', dependent: :nullify
  has_many :monthly_budgets, class_name: 'Management::MonthlyBudget', dependent: :nullify
  has_many :plan_schedules, class_name: 'Planning::PlanSchedule', dependent: :nullify
  has_many :units, class_name: 'Resources::Unit', dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :tenant_id }
  validates :code, presence: true, uniqueness: { scope: :tenant_id }
  validates :invitation_code, uniqueness: true, allow_nil: true

  attribute :active, :boolean, default: true

  before_create :generate_invitation_code

  def regenerate_invitation_code!
    loop do
      self.invitation_code = SecureRandom.alphanumeric(8).upcase
      break unless Store.exists?(invitation_code: invitation_code)
    end
    save!
  end

  private

  def generate_invitation_code
    return if invitation_code.present?
    
    loop do
      self.invitation_code = SecureRandom.alphanumeric(8).upcase
      break unless Store.exists?(invitation_code: invitation_code)
    end
  end
end
