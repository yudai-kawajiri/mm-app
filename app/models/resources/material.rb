# frozen_string_literal: true

# Material
#
# 材料モデル - 寿司ネタなどの原材料を管理
#
# 使用例:
#   Material.create(name: "本マグロ", measurement_type: "weight", category_id: 1)
#   Material.search_by_name("マグロ")
#   material.weight_based?
class Resources::Material < ApplicationRecord
  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include NameSearchable
  include UserAssociatable
  include Copyable
  include HasReading

  # 関連付け
  # フォーム定数
  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  belongs_to :category, class_name: "Resources::Category"
  belongs_to :production_unit, class_name: "Resources::Unit", optional: true
  belongs_to :unit_for_product, class_name: "Resources::Unit"
  belongs_to :unit_for_order, class_name: "Resources::Unit"
  belongs_to :order_group, class_name: "Resources::MaterialOrderGroup", optional: true, counter_cache: :materials_count

  # 多対多の関連
  has_many :product_materials, class_name: "Planning::ProductMaterial", dependent: :restrict_with_error
  has_many :products, through: :product_materials, class_name: "Resources::Product"

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_id }
  validates :reading, uniqueness: { scope: :category_id }, allow_blank: true
  validates :measurement_type, presence: true, inclusion: { in: %w[weight count] }
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  # 重量ベースの場合のバリデーション
  validates :unit_weight_for_order,
            presence: true,
            numericality: { greater_than: 0 },
            if: :weight_based?

  validates :default_unit_weight,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true,
            if: :weight_based?

  # 個数ベースの場合のバリデーション
  validates :pieces_per_order_unit,
            presence: true,
            numericality: { greater_than: 0, only_integer: true },
            if: :count_based?

  # 一覧画面用：登録順（新しい順）
  scope :for_index, -> { includes(:category, :unit_for_product, :unit_for_order).order(created_at: :desc) }

  # セレクトボックス用：名前順
  scope :ordered, -> { order(:name) }

  # 表示順を更新
  #
  # @param material_ids [Array<Integer>] 材料IDの配列（並び順）
  # @return [void]
  def self.update_display_orders(material_ids)
    material_ids.each_with_index do |material_id, index|
      where(id: material_id).update_all(display_order: index + 1)
    end
  end

  # 重量ベースかどうかを判定
  #
  # @return [Boolean]
  def weight_based?
    measurement_type == "weight"
  end

  # 個数ベースかどうかを判定
  #
  # @return [Boolean]
  def count_based?
    measurement_type == "count"
  end

  # 発注単位の換算タイプを判定（後方互換性のため残す）
  #
  # @return [Symbol] :weight, :count, :pieces, :none
  def order_conversion_type
    return :weight if weight_based?
    return :count if count_based?

    if pieces_per_order_unit.present? && pieces_per_order_unit.positive?
      :pieces
    elsif unit_weight_for_order.to_f.positive?
      :weight
    else
      :none
    end
  end

  # 発注グループ名を取得
  #
  # @return [String, nil] 発注グループ名
  def order_group_name
    order_group&.name
  end

  # Copyable設定
  # 注意: product_materialsはコピーしない（独立したマスタデータのため）
  copyable_config(
    uniqueness_scope: :category_id,
    uniqueness_check_attributes: [ :name, :reading ]
  )
end
