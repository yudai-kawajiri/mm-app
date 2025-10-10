class Product < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable

  # 0: 下書き (初期値として最も安全) 1: 販売中 (公開状態) 2: 販売中止
  enum :status, { draft: 0, published: 1, discontinued: 2 }

  # アソシエーション
  belongs_to :user
  belongs_to :category

  has_many :product_materials, dependent: :destroy
  has_many :materials, through: :product_materials

  #消えていたActive Storageを再追記
  has_one_attached :image

  # バリデーション
  validates :name, presence: true
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_number, presence: true, length: { maximum: 4 }, uniqueness: { scope: :user_id }
  validates :status, presence: true
end