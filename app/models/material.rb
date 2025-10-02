class Material < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :category_id, presence: true

  # 各バリデーションを設定
  validates :name, presence: true
  validates :unit_for_product, presence: true
  validates :unit_for_order, presence: true

  # 数値項目は必須かつ0より大きい値のみ許可（エラー回避）
  validates :unit_weight_for_product,
            presence: true,
            numericality: { greater_than: 0 }

  validates :unit_weight_for_order,
            presence: true,
            numericality: { greater_than: 0 }
end
