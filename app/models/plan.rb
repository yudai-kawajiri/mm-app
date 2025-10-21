class Plan < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  # belongs_to :user
  include UserAssociatable
  # 関連付け
  belongs_to :category, optional: false
  has_many :product_plans, dependent: :destroy

  # ネストフォームの設定: ProductPlanの追加・更新・削除を許可
  # allow_destroy: true => 項目削除用チェックボックスを許可
  accepts_nested_attributes_for :product_plans,
    allow_destroy: true,
    reject_if: :reject_product_plans

  # status カラムに enum を定義
  enum :status, { draft: 0, completed: 1 }

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_id }

  private

  # product_id と production_count の両方が空の場合にレコードを無視する
  def reject_product_plans(attributes)
    attributes['product_id'].blank? && attributes['production_count'].blank?
  end

  # カテゴリIDでの絞り込み
  scope :filter_by_category_id, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }
end
