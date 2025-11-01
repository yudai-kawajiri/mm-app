class ProductMaterial < ApplicationRecord
  belongs_to :product
  belongs_to :material
  belongs_to :unit  # デフォルトで必須

  # バリデーション
  validates :material_id, presence: true
  validates :material_id, uniqueness: { scope: :product_id, message: "は既に登録されています" }

  validates :unit_id, presence: true  # ← これを追加（重要！）

  validates :quantity,
            presence: true,
            numericality: { greater_than: 0 }
end
