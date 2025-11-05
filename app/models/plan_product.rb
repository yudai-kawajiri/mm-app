class PlanProduct < ApplicationRecord
  # PaperTrailで変更履歴を記録
  has_paper_trail

  belongs_to :plan
  belongs_to :product

  # バリデーション (データの整合性のため必須)
  validates :production_count, presence: true, numericality: { greater_than: 0 }

  # 同じ計画に同じ製品を登録不可にする
  validates :product_id, uniqueness: { scope: :plan_id }

  # この商品で使う原材料の必要量を計算
  def material_requirements
    product.product_materials.includes(:material, :unit).map do |pm|
      {
        material: pm.material,
        material_id: pm.material.id,
        material_name: pm.material.name,
        quantity_per_product: pm.quantity,                           # 商品1個あたりの使用量
        total_quantity: pm.quantity * production_count,              # この計画での総使用量
        unit: pm.unit,
        unit_name: pm.unit.name,
        unit_weight: pm.unit_weight,                                 # 1単位あたりの重量
        total_weight: pm.total_weight * production_count,            # この計画での総重量
        order_unit_name: pm.order_unit_name,                         # 発注単位名
        required_order_quantity: calculate_order_quantity(pm)        # 発注量（切り上げ）
      }
    end
  end

  private

  # 発注量を計算（商品の生産数を考慮）
  def calculate_order_quantity(product_material)
    material = product_material.material
    total_quantity = product_material.quantity * production_count
    total_weight = product_material.total_weight * production_count

    case material.order_conversion_type
    when :pieces
      # 個数ベース（例: トレイ 100枚 ÷ 50枚/箱 = 2箱）
      (total_quantity.to_f / material.pieces_per_order_unit).ceil
    when :weight
      # 重量ベース（例: まぐろ 9600g ÷ 1000g/パック = 10パック）
      (total_weight / material.unit_weight_for_order).ceil
    else
      0
    end
  end
end
