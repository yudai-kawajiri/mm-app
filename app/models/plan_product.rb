class PlanProduct < ApplicationRecord
  belongs_to :plan
  belongs_to :product

  # バリデーション (データの整合性のため必須)
  validates :production_count, presence: true, numericality: { greater_than: 0 }

  # 同じ計画に同じ製品を登録不可にする
  validates :product_id, uniqueness: { scope: :plan_id }
end
