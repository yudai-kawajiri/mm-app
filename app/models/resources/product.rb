# frozen_string_literal: true

# Product
#
# 製品モデル - 寿司メニューなどの販売製品を管理
class Resources::Product < ApplicationRecord
  ITEM_NUMBER_MIN = 1
  ITEM_NUMBER_DIGITS = 4
  ITEM_NUMBER_MAX = 10**ITEM_NUMBER_DIGITS - 1

  has_paper_trail

  include NameSearchable
  include UserAssociatable
  include NestedAttributeTranslatable
  include Copyable
  include HasReading
  include StatusChangeable

  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  nested_attribute_translation :product_materials, "Planning::ProductMaterial"

  restrict_status_change_if_used_in :plan_products, foreign_key: :product_id, class_name: "Planning::PlanProduct"

  enum :status, { draft: 0, selling: 1, discontinued: 2 }

  belongs_to :tenant
  belongs_to :store, optional: true
  belongs_to :category, class_name: "Resources::Category"
  has_many :product_materials, class_name: "Planning::ProductMaterial", dependent: :destroy
  has_many :materials, through: :product_materials, class_name: "Resources::Material"
  has_many :plan_products, class_name: "Planning::PlanProduct", dependent: :restrict_with_error
  has_many :plans, through: :plan_products, class_name: "Resources::Plan", dependent: :restrict_with_error

  accepts_nested_attributes_for :product_materials,
    reject_if: :should_reject_product_material?,
    allow_destroy: true

  has_one_attached :image

  attr_accessor :remove_image

  after_save :purge_image, if: :remove_image_checked?

  validates :name, presence: true, uniqueness: { scope: [:category_id, :store_id] }
  validates :reading, presence: true, uniqueness: { scope: [:category_id, :store_id] }
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_number, presence: true, length: { maximum: ITEM_NUMBER_DIGITS }, uniqueness: { scope: [:category_id, :store_id] }
  validates :category_id, presence: true
  validates :status, presence: true
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  validate :prevent_category_change_if_in_use, on: :update

  scope :for_index, -> { includes(:category).order(created_at: :desc) }
  scope :ordered, -> { order(:name) }
  scope :by_display_order, -> { order(Arel.sql("display_order IS NULL, display_order ASC, name ASC")) }

  before_save :reject_duplicate_product_materials

  def self.update_display_orders(product_ids)
    product_ids.each_with_index do |product_id, index|
      where(id: product_id).update_all(display_order: index + 1)
    end
  end

  copyable_config(
    uniqueness_scope: [:category_id, :store_id],
    uniqueness_check_attributes: [:name, :reading],
    associations_to_copy: [:product_materials],
    additional_attributes: {
      item_number: :generate_unique_item_number,
      status: :draft
    }
  )

  private

  def should_reject_product_material?(attributes)
    attributes["material_id"].blank?
  end

  def reject_duplicate_product_materials
    grouped = product_materials.reject(&:marked_for_destruction?).group_by(&:material_id)

    grouped.each do |material_id, items|
      next if items.size <= 1

      Rails.logger.warn "Duplicate product_material detected: material_id=#{material_id}, count=#{items.size}"

      items[1..].each do |duplicate|
        Rails.logger.warn "  → Removing duplicate: id=#{duplicate.id || 'new'}"
        duplicate.mark_for_destruction
      end
    end
  end

  def purge_image
    image.purge
  end

  def remove_image_checked?
    remove_image.present? && remove_image != "0"
  end

  def generate_unique_item_number
    base_number = item_number.to_i
    counter = 1

    loop do
      new_number_int = base_number + counter

      if new_number_int > ITEM_NUMBER_MAX
        raise StandardError,
              I18n.t("activerecord.errors.models.resources/product.item_number_exceeded")
      end

      new_number = format("%0#{ITEM_NUMBER_DIGITS}d", new_number_int)
      break new_number unless self.class.exists?(
        item_number: new_number,
        category_id: category_id
      )

      counter += 1
    end
  end

  def prevent_category_change_if_in_use
    return unless category_id_changed?
    return if Planning::PlanProduct.where(product_id: id).count.zero?

    errors.add(:category_id, I18n.t('activerecord.errors.models.resources/product.category_in_use', record: "計画"))
  end
end
