# frozen_string_literal: true

# 単位モデル - 材料の製造単位、発注単位、使用単位を管理
class Resources::Unit < ApplicationRecord
  belongs_to :company
  include TranslatableAssociations
  has_paper_trail

  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  include NameSearchable
  include UserAssociatable
  include Copyable
  include HasReading

  enum :category, { production: 0, ordering: 1, manufacturing: 2 }

  # 削除抑制：他モデルで使用中の単位は削除不可とし、整合性を維持
  has_many :materials_as_product_unit,
            class_name: "Material",
            foreign_key: "unit_for_product_id",
            dependent: :restrict_with_error

  has_many :materials_as_order_unit,
            class_name: "Material",
            foreign_key: "unit_for_order_id",
            dependent: :restrict_with_error

  has_many :materials_as_production_unit,
            class_name: "Material",
            foreign_key: "production_unit_id",
            dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: [ :category, :store_id ] }
  validates :reading, presence: true, uniqueness: { scope: [ :category, :store_id ] }
  validates :category, presence: true
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  # 運用中の整合性担保：使用されている単位のカテゴリー変更を禁止
  validate :prevent_category_change_if_in_use, on: :update

  scope :for_index, -> { order(created_at: :desc) }
  scope :ordered, -> { order(:name) }

  scope :filter_by_category, lambda { |category|
    where(category: category) if category.present? && categories.key?(category.to_s)
  }

  copyable_config(
    uniqueness_scope: [ :category, :store_id ],
    uniqueness_check_attributes: [ :name ]
  )

  private

  # カテゴリー変更によるデータの不整合（例：発注単位が製造単位に変わる等）を防ぐ
  def prevent_category_change_if_in_use
    return unless category_changed?

    usage_details = []
    usage_details << I18n.t("activerecord.models.resources/material") if Resources::Material.where(unit_for_product_id: id).exists? ||
                                  Resources::Material.where(unit_for_order_id: id).exists?
    usage_details << I18n.t("activerecord.models.planning/product_material") if Planning::ProductMaterial.where(unit_id: id).exists?

    return if usage_details.empty?

    errors.add(:category, I18n.t("activerecord.errors.models.resources/unit.category_in_use", record: usage_details.join("、")))
  end
end
