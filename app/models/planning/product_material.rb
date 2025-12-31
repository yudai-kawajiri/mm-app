# frozen_string_literal: true

class Planning::ProductMaterial < ApplicationRecord
  has_paper_trail

  belongs_to :product, class_name: "Resources::Product"
  belongs_to :material, class_name: "Resources::Material"
  belongs_to :unit, class_name: "Resources::Unit"
  belongs_to :company, optional: true

  validates :material_id, presence: true, uniqueness: { scope: :product_id, message: :already_registered }
  validates :unit_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_weight, presence: true, numericality: { greater_than: 0 }

  # マルチテナント：親のProductからcompany_idを継承しDB側のNOT NULL制約エラーを防止
  before_validation :inherit_company_from_product
  before_save :normalize_numeric_fields

  def total_weight
    quantity * unit_weight
  end

  # 仕様：発注単位を下回らないよう、必要量は常に「切り上げ」で算出
  def required_order_quantity
    return 0 unless material

    case material.order_conversion_type
    when :pieces
      if material.pieces_per_order_unit&.positive?
        (quantity.to_f / material.pieces_per_order_unit).ceil
      else
        0
      end
    when :weight
      if material.unit_weight_for_order&.positive?
        (total_weight / material.unit_weight_for_order).ceil
      else
        0
      end
    else
      0
    end
  end

  def order_unit_name
    material&.unit_for_order&.name || I18n.t("common.not_set")
  end

  def order_quantity_display
    "#{required_order_quantity} #{order_unit_name}"
  end

  def order_quantity_detail
    case material.order_conversion_type
    when :pieces
      I18n.t("planning.product_material.order_quantity_detail.pieces",
            quantity: quantity,
            unit: unit.name,
            order_quantity: required_order_quantity,
            order_unit: order_unit_name)
    when :weight
      I18n.t("planning.product_material.order_quantity_detail.weight",
            weight: total_weight.round(1),
            order_quantity: required_order_quantity,
            order_unit: order_unit_name)
    else
      I18n.t("common.calculation_unavailable")
    end
  end

  private

  # 複雑な計算ロジックを分割し、メソッド名で意図を表現
  def inherit_company_from_product
    return unless product

    self.company_id ||= product.company_id if product.company_id.present?
  end

  # ユーザー入力の揺れ（全角・カンマ）を吸収するための正規化
  def normalize_numeric_fields
    self.quantity = normalize_number(quantity) if quantity.present?
    self.unit_weight = normalize_number(unit_weight) if unit_weight.present?
  end

  def normalize_number(value)
    return value if value.is_a?(Numeric)

    cleaned = value.to_s
      .tr("０-９", "0-9")
      .tr("ー−", "-")
      .tr("。．", ".")
      .gsub(/[,\s　]/, "")

    cleaned.include?(".") ? cleaned.to_f : cleaned.to_i
  end
end
