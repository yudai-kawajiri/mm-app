class Product < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable

  # 0: 下書き 1: 販売中  2: 販売中止
  enum :status, { draft: 0, selling: 1, discontinued: 2 }

  # アソシエーション
  belongs_to :user
  belongs_to :category

  has_many :product_materials, dependent: :destroy
  has_many :materials, through: :product_materials

  # ネストされたフォームから product_materials を受け入れる設定
  # allow_destroy: true で、削除フラグによるレコード削除を許可
  accepts_nested_attributes_for :product_materials, allow_destroy: true

  #消えていたActive Storageを再追記
  has_one_attached :image

  # 画像削除チェックボックス（:remove_image）を受け取るための属性
  attr_accessor :remove_image

  # 保存後に remove_image がチェックされていたら画像を削除する
  after_save :purge_image, if: :remove_image_checked?

  # バリデーション
  validates :name, presence: true
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_number, presence: true, length: { maximum: 4 }, uniqueness: { scope: :user_id }
  validates :status, presence: true

   # 🔴 追加: Categoryの名前を表示するための安全なメソッド 🔴
  def category_name_for_display
    # category (belongs_to) が存在すれば、その name 属性を返す
    category.present? ? category.name : ''
  end

   # 🔴 追加: 金額表示用のヘルパーメソッド 🔴
  # 呼び出し元: product.price_with_currency
  def price_with_currency
    # number_to_currency ヘルパーはビューまたはヘルパーで呼び出すのが正しいが、
    # Modelのメソッドとして定義するなら、ロジック自体はシンプルにする
    price # ビュー側で number_to_currency を使用するのが最もDRY
  end

  def translated_status
    return '' if status.blank?
    # Categoryと同様にI18n.tで正しいパスを指定し、強制的に翻訳させる
    I18n.t("activerecord.enums.product.status.#{self.status}")
  end

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