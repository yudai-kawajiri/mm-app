# frozen_string_literal: true

# Store
#
# 店舗モデル
# - 1つの会社（Tenant）に複数の店舗が所属
# - データは店舗ごとに完全分離（他店舗のデータは閲覧不可）
class Store < ApplicationRecord
  belongs_to :tenant
  has_many :users, dependent: :nullify
  has_many :products, dependent: :nullify
  has_many :materials, dependent: :nullify
  has_many :categories, dependent: :nullify
  has_many :plans, dependent: :nullify
  has_many :material_order_groups, dependent: :nullify
  has_many :daily_targets, dependent: :nullify
  has_many :monthly_budgets, dependent: :nullify
  has_many :plan_schedules, dependent: :nullify
  has_many :units, dependent: :nullify

  validates :name, presence: true
  validates :code, uniqueness: { scope: :tenant_id }, allow_blank: true

  attribute :active, :boolean, default: true

  scope :active, -> { where(active: true) }
end
