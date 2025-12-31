# frozen_string_literal: true

# 製品モデル - 販売製品（寿司セットなど）を管理
class Resources::Product < ApplicationRecord
  include TranslatableAssociations

  # 品番の範囲設定（運用仕様に基づく）
  ITEM_NUMBER_MIN = 1
  ITEM_NUMBER_DIGITS = 4
  ITEM_NUMBER_MAX = (10**ITEM_NUMBER_DIGITS) - 1

  has_paper_trail

  include NameSearchable
  include UserAssociatable
  include NestedAttributeTranslatable
  include Copyable
  include HasReading
  include StatusChangeable

  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  # 中間テーブルの翻訳設定
  nested_attribute_translation :product_materials, "Planning::ProductMaterial"

  # ステータス変更制限：計画に使用されている場合は変更不可
  restrict_status_change_if_used_in :plan_products,
                                    foreign_key: :product_id,
                                    class_name: "Planning::PlanProduct"

  # ステータス定義
  enum :status, { draft: 0, selling: 1, discontinued: 2 }

  # 関連付け
  belongs_to :company
  belongs_to :store, optional: true
  belongs_to :category, class_name: "Resources::Category"

  has_many :product_materials, class_name: "Planning::ProductMaterial", dependent: :destroy
  has_many :materials, through: :product_materials, class_name: "Resources::Material"

  has_many :plan_products, class_name: "Planning::PlanProduct", dependent: :restrict_with_error
  has_many :plans, through: :plan_products, class_name: "Resources::Plan", dependent: :restrict_with_error

  # ネストした属性の受け入れ（原材料の同時保存用）
  accepts_nested_attributes_for :product_materials,
                                reject_if: :should_reject_product_material?,
                                allow_destroy: true

  has_one_attached :image
  attr_accessor :remove_image

  # 保存前・後のコールバック
  before_save :reject_duplicate_product_materials
  after_save :purge_image, if: :remove_image_checked?

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: [ :category_id, :store_id ] }
  validates :reading, presence: true, uniqueness: { scope: [ :category_id, :store_id ] }
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_number, presence: true, length: { maximum: ITEM_NUMBER_DIGITS },
                          uniqueness: { scope: [ :category_id, :store_id ] }
  validates :category_id, presence: true
  validates :status, presence: true
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  validate :prevent_category_change_if_in_use, on: :update

  # スコープ
  scope :for_index, -> { includes(:category).order(created_at: :desc) }
  scope :ordered, -> { order(:name) }
  scope :by_display_order, -> { order(Arel.sql("display_order IS NULL, display_order ASC, name ASC")) }

  # クラスメソッド：並び順の一括更新
  def self.update_display_orders(product_ids)
    transaction do
      product_ids.each_with_index do |id, index|
        where(id: id).update_all(display_order: index + 1)
      end
    end
  end

  # Copyable設定
  copyable_config(
    uniqueness_scope: [ :category_id, :store_id ],
    uniqueness_check_attributes: [ :name, :reading ],
    associations_to_copy: [ :product_materials ],
    status_on_copy: :draft,
    additional_attributes: {
      item_number: :generate_unique_item_number
    }
  )

  private

  # 原材料が空の場合は保存を拒否
  def should_reject_product_material?(attributes)
    attributes["material_id"].blank?
  end

  # 重複した原材料の登録を自動防止
  def reject_duplicate_product_materials
    grouped = product_materials.reject(&:marked_for_destruction?).group_by(&:material_id)

    grouped.each do |material_id, items|
      next if items.size <= 1
      items[1..].each(&:mark_for_destruction)
    end
  end

  def purge_image
    image.purge
  end

  def remove_image_checked?
    remove_image.present? && remove_image != "0"
  end

  # コピー時にユニークな品番を自動生成（空き番号探索）
  def generate_unique_item_number
    base_number = item_number.to_i
    counter = 1

    loop do
      new_number_int = base_number + counter
      if new_number_int > ITEM_NUMBER_MAX
        raise StandardError, I18n.t("activerecord.errors.models.resources/product.item_number_exceeded")
      end

      new_number = format("%0#{ITEM_NUMBER_DIGITS}d", new_number_int)
      break new_number unless self.class.exists?(item_number: new_number, category_id: category_id)

      counter += 1
    end
  end

  # 計画で使用されている場合、カテゴリー変更によるデータ不整合を防止
  def prevent_category_change_if_in_use
    return unless category_id_changed?
    # exists? を使ってパフォーマンスを最適化
    return unless plan_products.exists?

    errors.add(:category_id, I18n.t("activerecord.errors.models.resources/product.category_in_use",
                                    record: Planning::PlanProduct.model_name.human))
  end
end
