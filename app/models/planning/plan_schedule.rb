# frozen_string_literal: true

class Planning::PlanSchedule < ApplicationRecord
  has_paper_trail
  include UserAssociatable

  belongs_to :plan, class_name: "Resources::Plan", optional: true

  validates :scheduled_date, presence: true, uniqueness: { scope: :store_id }
  validates :status, presence: true
  validates :actual_revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # 企業の整合性を保つため、保存前に親(Plan)から会社情報を引き継ぐ
  before_validation :set_company_and_store_id, on: :create

  enum :status, { scheduled: 0, completed: 1, cancelled: 2 }

  scope :for_date, ->(date) { where(scheduled_date: date) }
  scope :for_month, lambda { |year, month|
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(scheduled_date: start_date..end_date)
  }
  scope :recent, -> { order(scheduled_date: :desc) }

  delegate :name, :description, :category, :products, to: :plan, prefix: true

  # 複数計画を横断した材料必要量の集計ロジック
  def self.material_requirements_for_date(date)
    # N+1防止のため、深くネストされた関連を一括ロード
    schedules = where(scheduled_date: date)
                .includes(plan: { plan_products: { product: { product_materials: [ :material, :unit ] } } })

    requirements = {}

    schedules.each do |schedule|
      schedule.plan.aggregated_material_requirements.each do |req|
        material_id = req[:material_id]
        if requirements[material_id]
          requirements[material_id][:total_quantity] += req[:total_quantity]
          requirements[material_id][:total_weight] += req[:total_weight]
          requirements[material_id][:required_order_quantity] += req[:required_order_quantity]
          requirements[material_id][:plans] ||= []
          requirements[material_id][:plans] << schedule.plan.name
        else
          requirements[material_id] = req.dup
          requirements[material_id][:plans] = [ schedule.plan.name ]
        end
      end
    end

    requirements.values.sort_by { |req| req[:material_name] }
  end

  def current_planned_revenue
    snapshot_total_cost
  end

  def expected_revenue
    current_planned_revenue
  end

  def has_actual?
    actual_revenue.present?
  end

  def revenue_variance
    (actual_revenue || 0) - expected_revenue
  end

  alias_method :variance, :revenue_variance

  def achievement_rate
    return nil unless has_actual?
    return 0 if expected_revenue.zero?

    (actual_revenue / expected_revenue * 100).round(1)
  end

  def today?
    scheduled_date == Date.current
  end


  def past?
    scheduled_date < Date.current
  end

  def future?
    scheduled_date > Date.current
  end

  # --- スナップショット機能 ---
  # マスターデータが変更されても、スケジュール時点の構成と売上を固定するために使用

  def has_snapshot?
    plan_products_snapshot.present? && plan_products_snapshot["products"].present?
  end

  def update_products_snapshot(products_data)
    snapshot = build_products_snapshot(products_data)
    if plan.present?
      snapshot["materials_summary"] = plan.calculate_materials_summary || []
    end
    update(plan_products_snapshot: snapshot)
  end

  def create_snapshot_from_plan
    products_data = plan.plan_products.map do |pp|
      { product_id: pp.product_id, production_count: pp.production_count }
    end
    update_products_snapshot(products_data)
  end

  def create_snapshot_from_products(products_hash)
    hash = case products_hash
    when ActionController::Parameters
              products_hash.to_unsafe_h
    when Hash
              products_hash
    else
              products_hash.to_h
    end

    products_data = hash.map do |product_id, production_count|
      { product_id: product_id.to_i, production_count: production_count.to_i }
    end

    update_products_snapshot(products_data)
  end

  def snapshot_products
    return [] unless has_snapshot?

    plan_products_snapshot["products"].map do |product_data|
      product = Resources::Product.find(product_data["product_id"])
      {
        product: product,
        production_count: product_data["production_count"],
        price: product_data["price"],
        subtotal: product_data["subtotal"]
      }
    end
  end

  def snapshot_products_for_json
    return [] unless has_snapshot?

    plan_products_snapshot["products"]
  end

  def snapshot_total_cost
    plan_products_snapshot.dig("total_cost") || 0
  end

  private

  def build_products_snapshot(products_data)
    products = []
    total_cost = 0

    products_data.each do |data|
      product = Resources::Product.find(data[:product_id])
      production_count = data[:production_count].to_i
      price = product.price
      subtotal = price * production_count

      products << {
        "product_id" => product.id,
        "name" => product.name,
        "item_number" => product.item_number,
        "production_count" => production_count,
        "price" => price,
        "subtotal" => subtotal
      }

      total_cost += subtotal
    end

    {
      "products" => products,
      "total_cost" => total_cost,
      "created_at" => Time.current.iso8601
    }
  end
  # company_id と store_id を plan から自動設定
  def set_company_and_store_id
    self.company_id ||= plan&.company_id
    self.store_id ||= plan&.store_id
  end

end