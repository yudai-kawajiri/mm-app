# frozen_string_literal: true

# 材料モデル - 原材料（寿司ネタ、調味料など）を管理
class Resources::Material < ApplicationRecord
  # 定数
  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  # 共通機能の組み込み
  include TranslatableAssociations
  include NameSearchable
  include UserAssociatable
  include Copyable
  include HasReading

  has_paper_trail

  # 関連付け
  belongs_to :company
  belongs_to :store, optional: true
  belongs_to :category, class_name: "Resources::Category"
  belongs_to :production_unit, class_name: "Resources::Unit", optional: true
  belongs_to :unit_for_product, class_name: "Resources::Unit" # 製品使用時の単位
  belongs_to :unit_for_order, class_name: "Resources::Unit"   # 発注時の単位
  belongs_to :order_group, class_name: "Resources::MaterialOrderGroup", optional: true, counter_cache: :materials_count

  has_many :product_materials, class_name: "Planning::ProductMaterial", dependent: :restrict_with_error
  has_many :products, through: :product_materials, class_name: "Resources::Product"

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: [ :category_id, :store_id ] }
  validates :reading, presence: true, uniqueness: { scope: [ :category_id, :store_id ] }
  validates :measurement_type, presence: true, inclusion: { in: %w[weight count] }
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  # 条件付きバリデーション（重量ベース）
  validates :unit_weight_for_order,
            presence: true,
            numericality: { greater_than: 0 },
            if: :weight_based?

  validates :default_unit_weight,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true,
            if: :weight_based?

  # 条件付きバリデーション（個数ベース）
  validates :pieces_per_order_unit,
            presence: true,
            numericality: { greater_than: 0, only_integer: true },
            if: :count_based?

  validate :prevent_category_change_if_in_use, on: :update

  # スコープ
  scope :for_index, -> { includes(:category, :unit_for_product, :unit_for_order).order(created_at: :desc) }
  scope :ordered, -> { order(:name) }

  # 並び順の一括更新
  def self.update_display_orders(material_ids)
    transaction do
      material_ids.each_with_index do |id, index|
        where(id: id).update_all(display_order: index + 1)
      end
    end
  end

  # --- ヘルパーメソッド ---

  def weight_based?
    measurement_type == "weight"
  end

  def count_based?
    measurement_type == "count"
  end

  # 発注計算時の変換タイプを判定
  def order_conversion_type
    return :weight if weight_based?
    return :count if count_based?

    if pieces_per_order_unit&.positive?
      :pieces
    elsif unit_weight_for_order.to_f.positive?
      :weight
    else
      :none
    end
  end

  def order_group_name
    order_group&.name
  end

  # Copyable設定
  copyable_config(
    uniqueness_scope: [ :category_id, :store_id ],
    uniqueness_check_attributes: [ :name, :reading ]
  )

  private

  # データ整合性チェック：使用中の材料はカテゴリー変更不可
  def prevent_category_change_if_in_use
    return unless category_id_changed?
    # 紐付くデータがあるかどうかの判定を exists? で効率化
    return unless product_materials.exists?

    errors.add(:category_id, I18n.t("activerecord.errors.models.resources/material.category_in_use", record: "商品"))
  end
end
