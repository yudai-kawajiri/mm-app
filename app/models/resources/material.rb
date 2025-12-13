# frozen_string_literal: true

# Material
#
# 材料モデル - 寿司ネタなどの原材料を管理
class Resources::Material < ApplicationRecord
  has_paper_trail

  include NameSearchable
  include UserAssociatable
  include Copyable
  include HasReading

  belongs_to :tenant
  belongs_to :store, optional: true

  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  belongs_to :category, class_name: "Resources::Category"
  belongs_to :production_unit, class_name: "Resources::Unit", optional: true
  belongs_to :unit_for_product, class_name: "Resources::Unit"
  belongs_to :unit_for_order, class_name: "Resources::Unit"
  belongs_to :order_group, class_name: "Resources::MaterialOrderGroup", optional: true, counter_cache: :materials_count

  has_many :product_materials, class_name: "Planning::ProductMaterial", dependent: :restrict_with_error
  has_many :products, through: :product_materials, class_name: "Resources::Product"

  validates :name, presence: true, uniqueness: { scope: [:category_id, :store_id] }
  validates :reading, presence: true, uniqueness: { scope: [:category_id, :store_id] }
  validates :measurement_type, presence: true, inclusion: { in: %w[weight count] }
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  validates :unit_weight_for_order,
            presence: true,
            numericality: { greater_than: 0 },
            if: :weight_based?

  validates :default_unit_weight,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true,
            if: :weight_based?

  validates :pieces_per_order_unit,
            presence: true,
            numericality: { greater_than: 0, only_integer: true },
            if: :count_based?

  # 使用中の原材料はカテゴリー変更不可（データ整合性を保つため）
  validate :prevent_category_change_if_in_use, on: :update

  scope :for_index, -> { includes(:category, :unit_for_product, :unit_for_order).order(created_at: :desc) }
  scope :ordered, -> { order(:name) }

  def self.update_display_orders(material_ids)
    material_ids.each_with_index do |material_id, index|
      where(id: material_id).update_all(display_order: index + 1)
    end
  end

  def weight_based?
    measurement_type == "weight"
  end

  def count_based?
    measurement_type == "count"
  end

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

  def order_group_name
    order_group&.name
  end

  copyable_config(
    uniqueness_scope: [:category_id, :store_id],
    uniqueness_check_attributes: [:name, :reading]
  )

  private

  def prevent_category_change_if_in_use
    return unless category_id_changed?

    usage_count = Planning::ProductMaterial.where(material_id: id).count
    return if usage_count.zero?

    usage = I18n.t('activerecord.errors.usage_formats.products', count: usage_count)
    errors.add(:category_id, I18n.t('activerecord.errors.models.resources/material.category_in_use', usage: usage))
  end
end
