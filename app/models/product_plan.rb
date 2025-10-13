class ProductPlan < ApplicationRecord
  belongs_to :plan
  belongs_to :product

  # バリデーション (データの整合性のため必須)
  validates :puroduction_count, presence: true, numericality: { greater_than: 0 }
end
