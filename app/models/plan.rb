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
  has_many :plan_schedules, dependent: :destroy

  # status カラムに enum を定義
  enum :status, { draft: 0, completed: 1 }

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_id }
  validates :category_id, presence: true
  validates :status, presence: true

  # インデックス表示用のスコープ (N+1問題対策と並び替え)
  scope :for_index, -> { includes(:category, :user).order(created_at: :desc) }

  # カテゴリIDでの絞り込み
  scope :filter_by_category_id, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }

  # 予定売上を計算（商品の売価 × 生産数量の合計）
  def expected_revenue
    plan_products.includes(:product).sum do |pp|
      pp.product.price * pp.production_count
    end
  end

  # ドロップダウン用の表示名（計画名と合計金額）
  def name_with_total
    total = expected_revenue
    "#{name}（¥#{total.to_s(:delimited)}）"
  end

  # 指定日にスケジュールを追加
  def add_schedule(date, note: nil)
    plan_schedules.create(scheduled_date: date, note: note)
  end

  # 複数日にスケジュールを一括追加
  def add_schedules(dates, note: nil)
    dates.map do |date|
      plan_schedules.find_or_create_by(scheduled_date: date) do |schedule|
        schedule.note = note
      end
    end
  end

  # 平日のみスケジュール追加
  def add_weekday_schedules(start_date, end_date, note: nil)
    dates = (start_date..end_date).select { |d| d.wday.between?(1, 5) }
    add_schedules(dates, note: note)
  end

  # スケジュールされている日数
  def scheduled_days_count
    plan_schedules.count
  end

  # 合計実績売上
  def total_actual_revenue
    plan_schedules.sum(:actual_revenue)
  end

  private

  # product_id と production_count の両方が空の場合にレコードを無視する
  def reject_plan_products(attributes)
    attributes['product_id'].blank? && attributes['production_count'].blank?
  end
end