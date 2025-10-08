class Product < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable

  # データベースに追加したstatusカラムをenumとして定義
  # 0:draft (下書き) , 1: active (販売中), 2:  (販売停止)
  enum status: {  draft: 1, active: 0, stopped: 2 }

  # 多対1
  belongs_to :user
  belongs_to :category

  #1対多
  has_many :product_materials, dependent: :destroy

  # 多対多
  has_many :materials, through: :product_materials

  # 1対1で画像を紐づけ
  has_one_attached :image

  # バリデーション
  validates :name, presence: true
  validates :item_number, presence: true, uniqueness: true
  # 金額のため小数点は含まないように設定
  validates :price,
            presence: true,
            numericality: { only_integer: true,
            greater_than: 0 }
end
