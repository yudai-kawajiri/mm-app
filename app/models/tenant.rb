# frozen_string_literal: true

# Tenant
#
# マルチテナントの会社（テナント）モデル
# - 各会社はサブドメインで識別（例: company-a.mm-app.com）
# - データは会社ごとに完全分離
class Tenant < ApplicationRecord
  has_many :stores, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :materials, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :material_order_groups, dependent: :destroy
  has_many :daily_targets, dependent: :destroy
  has_many :monthly_budgets, dependent: :destroy
  has_many :plan_schedules, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :product_materials, through: :products
  has_many :plan_products, through: :plans

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9-]+\z/ }

  attribute :active, :boolean, default: true
end
