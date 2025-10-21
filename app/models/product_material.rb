class ProductMaterial < ApplicationRecord
  belongs_to :product, optional: false
  belongs_to :material, optional: false
  belongs_to :unit, optional: false

  # 小数点も含めて設定
  validates :quantity,
            presence: true,
            numericality: { greater_than: 0}

  # 同じ商品に同じ原材料を登録不可にする
  validates :material_id, uniqueness: { scope: :product_id }
end
