class ProductPlan < ApplicationRecord
  belongs_to :plan
  belongs_to :product

  # バリデーション (データの整合性のため必須)
  validates :production_count, presence: true, numericality: { greater_than: 0 }
end
