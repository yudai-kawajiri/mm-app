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
  # 品番の定数
  ITEM_NUMBER_MIN = 1                              # 最小品番（0001）
  ITEM_NUMBER_DIGITS = 4                           # 品番の桁数
  ITEM_NUMBER_MAX = 10**ITEM_NUMBER_DIGITS - 1    # 最大品番（9999）

  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include NameSearchable
  include UserAssociatable
  include NestedAttributeTranslatable
  include Copyable
  include HasReading
  include StatusChangeable

  # フォーム定数
  DESCRIPTION_MAX_LENGTH = 500
  DESCRIPTION_ROWS = 3

  # ネストされた属性の翻訳設定
  nested_attribute_translation :product_materials, "Planning::ProductMaterial"

  # ステータス変更制限
  restrict_status_change_if_used_in :plan_products, foreign_key: :product_id, class_name: "Planning::PlanProduct"

  # 製品のステータス定義
  enum :status, { draft: 0, selling: 1, discontinued: 2 }

  # 関連付け
  belongs_to :category, class_name: "Resources::Category"
  has_many :product_materials, class_name: "Planning::ProductMaterial", dependent: :destroy
  has_many :materials, through: :product_materials, class_name: "Resources::Material"
  has_many :plan_products, class_name: "Planning::PlanProduct", dependent: :restrict_with_error
  has_many :plans, through: :plan_products, class_name: "Resources::Plan", dependent: :restrict_with_error

  # ネストされたフォームから product_materials を受け入れる
  accepts_nested_attributes_for :product_materials,
  reject_if: :should_reject_product_material?,
  allow_destroy: true

  # 画像アップロード機能
  has_one_attached :image

  # 画像削除用の仮想属性
  attr_accessor :remove_image

  # 画像削除処理
  after_save :purge_image, if: :remove_image_checked?

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_id }
  validates :reading, uniqueness: { scope: :category_id }, allow_blank: true
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_number, presence: true, length: { maximum: ITEM_NUMBER_DIGITS }, uniqueness: { scope: :category_id }
  validates :category_id, presence: true
  validates :status, presence: true
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH }, allow_blank: true

  # 一覧画面用：登録順（新しい順）
  scope :for_index, -> { includes(:category).order(created_at: :desc) }

  # セレクトボックス用：名前順
  scope :ordered, -> { order(:name) }

  # 印刷順でソート（display_order順、nullは最後）
  scope :by_display_order, -> { order(Arel.sql("display_order IS NULL, display_order ASC, name ASC")) }

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

  # Copyable設定
  copyable_config(
    uniqueness_scope: :category_id,
    uniqueness_check_attributes: [ :name, :reading ],
    associations_to_copy: [ :product_materials ],
    additional_attributes: {
      item_number: :generate_unique_item_number,
      status: :draft
    }
  )

  private

  def should_reject_product_material?(attributes)
    attributes["material_id"].blank?
  end

  # 重複した原材料を除外（最初の1つを残す）
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

  # 画像を削除
  def purge_image
    image.purge
  end

  # 画像削除チェックボックスがオンか確認
  def remove_image_checked?
    remove_image.present? && remove_image != "0"
  end

  # 一意な品番を生成
  #
  # コピー時に使用される。元の品番に1ずつ加算して、
  # 既存の品番と重複しない新しい品番を生成する。
  #
  # @return [String] 一意な品番（4桁ゼロパディング）
  # @raise [StandardError] 品番が上限（9999）を超えた場合
  def generate_unique_item_number
    base_number = item_number.to_i
    counter = 1

    loop do
      new_number_int = base_number + counter

      # 品番が最大値を超えたらエラー
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
end
