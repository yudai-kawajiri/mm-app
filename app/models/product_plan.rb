class ProductPlan < ApplicationRecord
  belongs_to :plan, optional: false
  belongs_to :product, optional: false

  # バリデーション (データの整合性のため必須)
  validates :production_count, presence: true, numericality: { greater_than: 0 }
end
