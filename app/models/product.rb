class Product < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  include UserAssociatable

  # 0: 下書き 1: 販売中  2: 販売中止
  enum :status, { draft: 0, selling: 1, discontinued: 2 }

  # アソシエーション
  belongs_to :category

  has_many :product_materials, dependent: :destroy
  has_many :materials, through: :product_materials
  has_many :plan_products, dependent: :destroy
  has_many :plans, through: :plan_products, dependent: :restrict_with_error

  # ネストされたフォームから product_materials を受け入れる設定
  accepts_nested_attributes_for :product_materials, allow_destroy: true

  # 消えていたActive Storageを再追記
  has_one_attached :image

  # 画像削除チェックボックス（:remove_image）を受け取るための属性
  attr_accessor :remove_image

  # 保存後に remove_image がチェックされていたら画像を削除する
  after_save :purge_image, if: :remove_image_checked?

  # バリデーション
  validates :name, presence: true
  validates :name, uniqueness: { scope: :category_id }
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_number, presence: true, length: { maximum: 4 }, uniqueness: { scope: :category_id }
  validates :category_id, presence: true
  validates :status, presence: true

  # インデックス表示用のスコープ (N+1問題対策と並び替え)
  scope :for_index, -> { includes(:category).order(created_at: :desc) }

  # 空の原材料レコードを除外
  before_validation :reject_blank_product_materials

  # 重複した原材料を除外
  before_save :reject_duplicate_product_materials

  private

  def reject_blank_product_materials
    product_materials.each do |pm|
      # material_id が空の場合は削除マーク
      pm.mark_for_destruction if pm.material_id.blank?
    end
  end

  def reject_duplicate_product_materials
    # 削除マークされていない原材料を material_id でグループ化
    grouped = product_materials.reject(&:marked_for_destruction?).group_by(&:material_id)

    grouped.each do |material_id, items|
      # 1つだけなら問題なし
      next if items.size <= 1

      # 2つ以上ある場合、最初の1つを残して残りを削除
      Rails.logger.warn "⚠️ Duplicate product_material detected: material_id=#{material_id}, count=#{items.size}"

      items[1..-1].each do |duplicate|
        Rails.logger.warn "  → Removing duplicate: id=#{duplicate.id || 'new'}"
        duplicate.mark_for_destruction
      end
    end
  end

  # 実際に画像を削除するメソッド
  def purge_image
    image.purge
  end

  # 画像削除チェックボックスがオンか確認するメソッド
  def remove_image_checked?
    # remove_imageがnilではない、かつ "0"（チェックオフの値）ではない場合にtrue
    remove_image.present? && remove_image != "0"
  end

  # 表示順でソート（display_orderが同じ場合はid順）
  scope :ordered, -> { order(:display_order, :id) } 

  # 表示順を更新するメソッド
  def self.update_display_orders(product_ids)
    product_ids.each_with_index do |product_id, index|
      Product.where(id: product_id).update_all(display_order: index + 1)
    end
  end
end
