# frozen_string_literal: true

# ProductMaterial
#
# 製品材料中間モデル - 製品と材料の多対多の関連を管理
#
# 使用例:
#   ProductMaterial.create(product_id: 1, material_id: 1, quantity: 2, unit_weight: 50, unit_id: 1)
#   pm.total_weight
#   pm.required_order_quantity
class Planning::ProductMaterial < ApplicationRecord
  # 変更履歴の記録
  has_paper_trail

  # 関連付け
  belongs_to :product, class_name: 'Resources::Product'
  belongs_to :material, class_name: 'Resources::Material'
  belongs_to :unit, class_name: 'Resources::Unit'

  # バリデーション
  validates :material_id, presence: true, uniqueness: { scope: :product_id, message: :already_registered }
  validates :unit_id, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_weight, presence: true, numericality: { greater_than: 0 }

  # 保存前に数値フィールドを正規化（全角→半角変換）
  before_save :normalize_numeric_fields

  # この商品材料の総重量を計算
  #
  # @return [Float] 総重量
  def total_weight
    quantity * unit_weight
  end

  # 必要な発注量を計算
  #
  # @return [Integer] 発注量
  def required_order_quantity
    return 0 unless material

    case material.order_conversion_type
    when :pieces
      # 個数ベース（例: トレイ 8枚使用 ÷ 50枚/箱 = 0.16箱 → 1箱）
      if material.pieces_per_order_unit&.positive?
        (quantity.to_f / material.pieces_per_order_unit).ceil
      else
        0
      end
    when :weight
      # 重量ベース（例: まぐろ 96g ÷ 1000g/パック = 0.096パック → 1パック）
      if material.unit_weight_for_order&.positive?
        (total_weight / material.unit_weight_for_order).ceil
      else
        0
      end
    else
      0
    end
  end

  # 発注単位名
  #
  # @return [String] 発注単位名
  def order_unit_name
    material&.unit_for_order&.name || I18n.t('common.not_set')
  end

  # 表示用（例: "1 パック", "2 箱"）
  #
  # @return [String] 発注量の表示文字列
  def order_quantity_display
    "#{required_order_quantity} #{order_unit_name}"
  end

  # 発注量の詳細（例: "96g → 1パック"）
  #
  # @return [String] 発注量の詳細文字列
  def order_quantity_detail
    case material.order_conversion_type
    when :pieces
      I18n.t('planning.product_material.order_quantity_detail.pieces',
             quantity: quantity,
             unit: unit.name,
             order_quantity: required_order_quantity,
             order_unit: order_unit_name)
    when :weight
      I18n.t('planning.product_material.order_quantity_detail.weight',
             weight: total_weight.round(1),
             order_quantity: required_order_quantity,
             order_unit: order_unit_name)
    else
      I18n.t('common.calculation_unavailable')
    end
  end

  private

  # 数値フィールドを正規化（全角→半角、カンマ・スペース削除）
  def normalize_numeric_fields
    self.quantity = normalize_number(quantity) if quantity.present?
    self.unit_weight = normalize_number(unit_weight) if unit_weight.present?
  end

  # 数値を正規化して数値型に変換
  #
  # @param value [String, Numeric] 変換する値
  # @return [Numeric] 正規化された数値
  def normalize_number(value)
    return value if value.is_a?(Numeric)

    # 全角→半角、カンマ削除、スペース削除
    cleaned = value.to_s
      .tr('０-９', '0-9')
      .tr('ー−', '-')
      .tr('。．', '.')
      .gsub(/[,\s　]/, '')

    # 小数点があればFloatに、なければIntegerに変換
    cleaned.include?('.') ? cleaned.to_f : cleaned.to_i
  end
end
