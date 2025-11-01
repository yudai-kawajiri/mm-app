class ProductMaterial < ApplicationRecord
  belongs_to :product
  belongs_to :material
  belongs_to :unit

  # バリデーション
  validates :material_id, presence: true
  validates :material_id, uniqueness: { scope: :product_id, message: "は既に登録されています" }
  validates :unit_id, presence: true

  validates :quantity,
            presence: true,
            numericality: { greater_than: 0 }

  validates :unit_weight,
            presence: true,
            numericality: { greater_than: 0 }

  # この商品材料の総重量を計算
  def total_weight
    quantity * unit_weight
  end

  # 必要な発注量を計算
  def required_order_quantity
    return 0 unless material

    case material.order_conversion_type
    when :pieces
      # 個数ベース（例: トレイ 8枚使用 ÷ 50枚/箱 = 0.16箱 → 1箱）
      (quantity.to_f / material.pieces_per_order_unit).ceil
    when :weight
      # 重量ベース（例: まぐろ 96g ÷ 1000g/パック = 0.096パック → 1パック）
      (total_weight / material.unit_weight_for_order).ceil
    else
      0
    end
  end

  # 発注単位名
  def order_unit_name
    material&.unit_for_order&.name || "未設定"
  end

  # 表示用（例: "1 パック", "2 箱"）
  def order_quantity_display
    "#{required_order_quantity} #{order_unit_name}"
  end

  # 発注量の詳細（例: "96g → 1パック"）
  def order_quantity_detail
    case material.order_conversion_type
    when :pieces
      "#{quantity}#{unit.name} → #{required_order_quantity}#{order_unit_name}"
    when :weight
      "#{total_weight.round(1)}g → #{required_order_quantity}#{order_unit_name}"
    else
      "計算不可"
    end
  end
end
