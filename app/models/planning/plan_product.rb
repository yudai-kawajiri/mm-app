# frozen_string_literal: true

# 計画製品中間モデル - 計画と製品の多対多の関連を管理
class Planning::PlanProduct < ApplicationRecord
  has_paper_trail

  belongs_to :plan, class_name: "Resources::Plan"
  belongs_to :product, class_name: "Resources::Product"

  validates :production_count, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :product_id, uniqueness: { scope: :plan_id }
  validates :product_id, presence: true

  before_validation :set_company_id, on: :create
  before_save :normalize_numeric_fields

  def material_requirements
    product.product_materials.includes(:material, :unit).map do |pm|
      {
        material: pm.material,
        material_id: pm.material.id,
        material_name: pm.material.name,
        quantity: pm.quantity,                                       # 数量（例: 1個）
        unit_weight: pm.unit_weight,                                 # 商品単位重量（例: 12g）
        weight_per_product: pm.total_weight,                         # 商品1個当の重量（quantity × unit_weight）
        total_quantity: pm.quantity * production_count,              # この計画での総数量
        total_weight: pm.total_weight * production_count,            # この計画での総重量
        unit: pm.unit,
        unit_name: pm.unit.name
      }
    end
  end

  private

  # company_id を plan から自動設定
  def set_company_id
    self.company_id ||= plan&.company_id
  end

  # 数値フィールドを正規化（全角→半角、カンマ・スペース削除）
  def normalize_numeric_fields
    self.production_count = normalize_number(production_count) if production_count.present?
  end

  def normalize_number(value)
    return value.to_i if value.is_a?(Numeric)

    # 全角→半角、カンマ削除、スペース削除、小数点削除
    cleaned = value.to_s
      .tr("０-９", "0-9")
      .tr("ー−", "-")
      .gsub(/[,\s　．。.]/, "")

    cleaned.to_i
  end
end
