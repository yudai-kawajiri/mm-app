# frozen_string_literal: true

# PlanProduct
#
# 計画製品中間モデル - 計画と製品の多対多の関連を管理
#
# 使用例:
#   PlanProduct.create(plan_id: 1, product_id: 1, production_count: 100)
#   pp.material_requirements
class Planning::PlanProduct < ApplicationRecord
  # 変更履歴の記録
  has_paper_trail

  # 関連付け
  belongs_to :plan, class_name: "Resources::Plan"
  belongs_to :product, class_name: "Resources::Product"

  # バリデーション
  validates :production_count, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :product_id, uniqueness: { scope: :plan_id }

  # 保存前に数値フィールドを正規化（全角→半角変換）
  before_save :normalize_numeric_fields

  # この商品で使う原材料の必要量を計算
  #
  # @return [Array<Hash>] 原材料必要量の配列
  def material_requirements
    product.product_materials.includes(:material, :unit).map do |pm|
      {
        material: pm.material,
        material_id: pm.material.id,
        material_name: pm.material.name,
        quantity: pm.quantity,                                       # 数量（例: 1個）
        unit_weight: pm.unit_weight,                                 # 商品単位重量（例: 12g）
        weight_per_product: pm.total_weight,                         # 商品1個あたりの重量（quantity × unit_weight）
        total_quantity: pm.quantity * production_count,              # この計画での総数量
        total_weight: pm.total_weight * production_count,            # この計画での総重量
        unit: pm.unit,
        unit_name: pm.unit.name
      }
    end
  end

  private

  # 数値フィールドを正規化（全角→半角、カンマ・スペース削除）
  def normalize_numeric_fields
    self.production_count = normalize_number(production_count) if production_count.present?
  end

  # 数値を正規化して数値型に変換
  #
  # @param value [String, Numeric] 変換する値
  # @return [Numeric] 正規化された数値
  def normalize_number(value)
    return value.to_i if value.is_a?(Numeric)  # ← .to_i に変更

    # 全角→半角、カンマ削除、スペース削除、小数点削除
    cleaned = value.to_s
      .tr("０-９", "0-9")
      .tr("ー−", "-")
      .gsub(/[,\s　．。.]/, "")  # ← 小数点も削除

    cleaned.to_i  # ← 最後も .to_i
  end
end
