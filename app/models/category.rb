class Category < ApplicationRecord
  # ユーザーとの関連付け
  belongs_to :user
  # Materialモデルとの関連付け
  has_many :materials, dependent: :destroy
  # カテゴリ名が空欄でないこと、一意であることを要求
  validates :name, presence: true, uniqueness: { scope: :user_id }
  # カテゴリ分類が空欄でないことを要求
  validates :category_type, presence: true
end
