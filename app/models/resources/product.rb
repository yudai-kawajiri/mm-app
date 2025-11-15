# frozen_string_literal: true

# Product
#
# 製品モデル - 寿司メニューなどの販売製品を管理
#
# 使用例:
#   Product.create(name: "まぐろ", price: 500, item_number: "0001", category_id: 1)
#   Product.search_by_name("まぐろ")
#   product.materials
class Resources::Product < ApplicationRecord
  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include NameSearchable
  include UserAssociatable
  include NestedAttributeTranslatable

  # ネストされた属性の翻訳設定
  nested_attribute_translation :product_materials, 'Planning::ProductMaterial'

  # 製品のステータス定義
  enum :status, { draft: 0, selling: 1, discontinued: 2 }

  # 関連付け
  belongs_to :category, class_name: 'Resources::Category'
  has_many :product_materials, class_name: 'Planning::ProductMaterial', dependent: :destroy
  has_many :materials, through: :product_materials, class_name: 'Resources::Material'
  has_many :plan_products, class_name: 'Planning::PlanProduct', dependent: :restrict_with_error
  has_many :plans, through: :plan_products, class_name: 'Resources::Plan', dependent: :restrict_with_error

  # ネストされたフォームから product_materials を受け入れる
  accepts_nested_attributes_for :product_materials, allow_destroy: true

  # 画像アップロード機能
  has_one_attached :image

  # 画像削除用の仮想属性
  attr_accessor :remove_image

  # 画像削除処理
  after_save :purge_image, if: :remove_image_checked?

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_id }
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_number, presence: true, length: { maximum: 4 }, uniqueness: { scope: :category_id }
  validates :category_id, presence: true
  validates :status, presence: true

  # インデックス表示用（N+1問題対策と並び替え）
  scope :for_index, -> { includes(:category).order(created_at: :desc) }

  # 表示順でソート
  scope :ordered, -> { order(display_order: :asc, id: :asc) }

  # 空の原材料レコードを除外
  before_validation :reject_blank_product_materials


  # 重複した原材料を除外
  before_save :reject_duplicate_product_materials

  # 表示順を更新
  #
  # @param product_ids [Array<Integer>] 製品IDの配列（並び順）
  # @return [void]
  def self.update_display_orders(product_ids)
    product_ids.each_with_index do |product_id, index|
      where(id: product_id).update_all(display_order: index + 1)
    end
  end

  private

  # material_id が空の原材料を削除マーク
  def reject_blank_product_materials
    product_materials.each do |pm|
      pm.mark_for_destruction if pm.material_id.blank?
    end
  end

  # 重複した原材料を除外（最初の1つを残す）
  def reject_duplicate_product_materials
    grouped = product_materials.reject(&:marked_for_destruction?).group_by(&:material_id)

    grouped.each do |material_id, items|
      next if items.size <= 1

      Rails.logger.warn "⚠️ Duplicate product_material detected: material_id=#{material_id}, count=#{items.size}"

      items[1..].each do |duplicate|
        Rails.logger.warn "  → Removing duplicate: id=#{duplicate.id || 'new'}"
        duplicate.mark_for_destruction
      end
    end
  end

  # 画像を削除
  def purge_image
    image.purge
  end

  # 画像削除チェックボックスがオンか確認
  def remove_image_checked?
    remove_image.present? && remove_image != "0"
  end
end
