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

  #消えていたActive Storageを再追記
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
  # 🆕 Branch 8: category_id と status のバリデーションを追加
  validates :category_id, presence: true
  validates :status, presence: true

  private

  # 実際に画像を削除するメソッド
  def purge_image
    image.purge
  end

  # 画像削除チェックボックスがオンか確認するメソッド
  def remove_image_checked?
    # remove_imageがnilではない、かつ "0"（チェックオフの値）ではない場合にtrue
    remove_image.present? && remove_image != '0'
  end
end
