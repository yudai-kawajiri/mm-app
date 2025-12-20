# frozen_string_literal: true

# ProductMaterial
#
# 製品材料中間モデル - 製品と材料の多対多の関連を管理
#
# 【マルチテナント対応】
# 親モデル（Product）から tenant_id を自動的に継承
# ネストされた属性として保存される際も、親のスコープを維持
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

  # マルチテナント: 親の Product から tenant_id を自動継承
  #
  # 【なぜ before_validation か】
  # NOT NULL制約エラーを防ぐため、バリデーション前に設定
  # accepts_nested_attributes_for 経由での保存時も確実に実行される
  before_validation :inherit_company_from_product

  before_save :normalize_numeric_fields

  def total_weight
    quantity * unit_weight
  end

  # 必要な発注量を計算
  #
  # 【業務ロジック】
  # - 個数ベース: 使用個数 ÷ 発注単位あたり個数 → 切り上げ
  # - 重量ベース: 総重量 ÷ 発注単位あたり重量 → 切り上げ
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

  # 親の Product から tenant_id を継承
  #
  # 【実装意図】
  # ネストされた属性として保存される ProductMaterial に対し、
  # 親の Product が持つ tenant_id を自動コピーし、データ整合性を保証
  def inherit_company_from_product
    return unless product

    self.company_id ||= product.company_id if product.company_id.present?
  end

  # 数値フィールドを正規化（全角→半角、カンマ削除）
  #
  # 【目的】ユーザー入力の多様性を吸収
  # 例: "１,０００" → 1000, "１２３。５" → 123.5
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
