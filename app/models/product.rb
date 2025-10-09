class Product < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :category

  has_many :product_materials, dependent: :destroy
  has_many :materials, through: :product_materials

  # バリデーション
  validates :name, presence: true
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_number, presence: true, length: { maximum: 4 }, uniqueness: { scope: :user_id }
  validates :status, presence: true
end