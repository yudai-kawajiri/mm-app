# frozen_string_literal: true

# Category
#
# カテゴリーモデル - 材料、製品、計画の分類を管理
#
# カテゴリー種別:
#   - material: 材料カテゴリー (0)
#   - product: 製品カテゴリー (1)
#   - plan: 計画カテゴリー (2)
class Resources::Category < ApplicationRecord
  has_paper_trail

  include NameSearchable
  include UserAssociatable
  include Copyable
  include HasReading

  enum :category_type, { material: 0, product: 1, plan: 2 }

  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  has_many :materials, class_name: "Resources::Material", dependent: :restrict_with_error
  has_many :products, class_name: "Resources::Product", dependent: :restrict_with_error
  has_many :plans, class_name: "Resources::Plan", dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: [:category_type, :store_id] }
  validates :category_type, presence: true
  validates :reading, presence: true
  validate :reading_uniqueness_within_store_and_type
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  validate :prevent_category_type_change_if_in_use, on: :update

  scope :for_index, -> { order(created_at: :desc) }
  scope :ordered, -> { order(:name) }
  scope :for_materials, -> { where(category_type: :material) }
  scope :for_products, -> { where(category_type: :product) }
  scope :for_plans, -> { where(category_type: :plan) }

  copyable_config(
    uniqueness_scope: [:category_type, :store_id],
    uniqueness_check_attributes: [:name, :reading]
  )

  private

  def reading_uniqueness_within_store_and_type
    return if reading.blank?

    existing = self.class
      .where(reading: reading, category_type: category_type, store_id: store_id)
      .where.not(id: id)
      .exists?

    errors.add(:reading, :taken) if existing
  end

  def prevent_category_type_change_if_in_use
    return unless category_type_changed?

    usage_details = []
    usage_details << "商品" if products.exists?
    usage_details << "原材料" if materials.exists?
    usage_details << "計画" if plans.exists?

    return if usage_details.empty?

    errors.add(:category_type, I18n.t('activerecord.errors.models.resources/category.category_type_in_use', record: usage_details.join('、')))
  end
end
