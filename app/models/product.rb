class Product < ApplicationRecord
  # 多対1
  belongs_to :user
  belongs_to :category

  #1対多
  has_many :product_materials, dependent: :destroy

  # 多対多
  has_many :materials, through: :product_materials

  # バリデーション
  validates :name, presence: true
  validates :item_number, presence: true, uniqueness: true
  # 金額のため小数点は含まないように設定
  validates :price,
            presence: true,
            numericality: { only_integer: true,
            greater_than: 0 }
end
