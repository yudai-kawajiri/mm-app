class Plan < ApplicationRecord
  # 関連付け
  belongs_to :category
  belongs_to :user
  has_many :product_plans, dependent: :destroy

  # ネストフォームの設定: ProductPlanの追加・更新・削除を許可
  # allow_destroy: true => 項目削除用チェックボックスを許可
  # reject_if: :all_blank => すべてのフィールドが空のレコードを無視
  accepts_nested_attributes_for :product_plans, allow_destroy: true, reject_if: :all_blank

  # バリデーション
  validates :plan_date, presence: true
  validates :name, presence: true
  validates :category_id, presence: true

end
