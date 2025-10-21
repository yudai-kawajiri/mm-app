class Plan < ApplicationRecord
   # 名前検索スコープを組み込み
  include NameSearchable
  # belongs_to :user
  include UserAssociatable
  # 関連付け
  belongs_to :category
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

  #  検索ロジックの統合メソッド
  # 検索パラメーター全体を受け取り、複数のフィルタリングを一括で適用する
  def self.search_and_filter(params)
    results = all

    results = results.search_by_name(params[:q]) if params[:q].present?
    results = results.filter_by_category_id(params[:category_id]) if params[:category_id].present?

    results
  end

  private

  def category_name_for_display
    self.category.name
  end

  def translated_status
    # enum で定義されたステータスの値 (draft, completedなど) に対応する、
    # I18nファイルに定義された日本語名を取得します。
    I18n.t("activerecord.enums.plan.status.#{self.status}")
  end

  # product_id と production_count の両方が空の場合にレコードを無視する
  def reject_product_plans(attributes)
    attributes['product_id'].blank? && attributes['production_count'].blank?
  end

  # カテゴリIDでの絞り込み
  scope :filter_by_category_id, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }
end
