class Plan < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  # belongs_to :user
  include UserAssociatable
  # 関連付け
  belongs_to :category, optional: false
  has_many :plan_products, inverse_of: :plan, dependent: :destroy
  accepts_nested_attributes_for :plan_products,
    { allow_destroy: true,
    reject_if: :reject_plan_products }

  # status カラムに enum を定義
  enum :status, { draft: 0, completed: 1 }

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_id }

  private

  # product_id と production_count の両方が空の場合にレコードを無視する
  def reject_plan_products(attributes)
    attributes['product_id'].blank? && attributes['production_count'].blank?
  end

  # カテゴリIDでの絞り込み
  scope :filter_by_category_id, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }
end
