class Plan < ApplicationRecord
  # 関連付け
  # 未 userとの関連
  belongs_to :category
  belongs_to :user
  has_many :product_plans, dependent: :destroy

  # ネストフォームの設定: ProductPlanの追加・更新・削除を許可
  # allow_destroy: true => 項目削除用チェックボックスを許可
  accepts_nested_attributes_for :product_plans,
    allow_destroy: true,
    reject_if: :reject_product_plans

  # status カラムに enum を定義
  enum :status, { draft: 0, completed: 1 }

  # バリデーション
  validates :name, presence: true, uniqueness: true
  validates :category_id, presence: true

  private

  def category_name_for_display
    self.category.name
  end

  def translated_status
    # enum で定義されたステータスの値 (draft, completedなど) に対応する、
    # I18nファイルに定義された日本語名を取得します。
    I18n.t("activerecord.attributes.plan.statuses.#{self.status}")
  end

  # product_id と production_count の両方が空の場合にレコードを無視する
  def reject_product_plans(attributes)
    attributes['product_id'].blank? && attributes['production_count'].blank?
  end
end
