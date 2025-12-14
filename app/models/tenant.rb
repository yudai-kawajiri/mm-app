# frozen_string_literal: true

# Tenant
#
# マルチテナントの会社（テナント）モデル
# - 各会社はサブドメインで識別（例: company-a.mm-app.com）
# - データは会社ごとに完全分離
class Tenant < ApplicationRecord
  has_many :stores, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :products, class_name: 'Resources::Product', dependent: :destroy
  has_many :materials, class_name: 'Resources::Material', dependent: :destroy
  has_many :categories, class_name: 'Resources::Category', dependent: :destroy
  has_many :plans, class_name: 'Resources::Plan', dependent: :destroy
  has_many :material_order_groups, class_name: 'Resources::MaterialOrderGroup', dependent: :destroy
  has_many :daily_targets, class_name: 'Management::DailyTarget', dependent: :destroy
  has_many :monthly_budgets, class_name: 'Management::MonthlyBudget', dependent: :destroy
  has_many :plan_schedules, class_name: 'Planning::PlanSchedule', dependent: :destroy
  has_many :units, class_name: 'Resources::Unit', dependent: :destroy
  has_many :product_materials, through: :products, class_name: 'Planning::ProductMaterial'
  has_many :plan_products, through: :plans, class_name: 'Planning::PlanProduct'

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9-]+\z/ }

  attribute :active, :boolean, default: true
end
