class PlanSchedule < ApplicationRecord
  # 関連付け (Association)
  belongs_to :plan

  # バリデーション (Validation)
  # 実施日は必須入力
  # uniqueness: { scope: :plan_id } により、同一のPlanに対し同じ日にスケジュールを重複作成できないようにする
  validates :scheduled_date, presence: true, uniqueness: { scope: :plan_id }
  # ステータスは必須
  validates :status, presence: true
  # 実績売上は0以上の数値のみ許可（nilも許可し、未入力に対応）
  validates :actual_revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # eum
  # スケジュールの現在の状態を定義
  enum :status, { scheduled: 0, completed: 1, cancelled: 2 }

  # スコープ (Scope)

  # 指定された日付のスケジュールを取得
  scope :for_date, ->(date) { where(scheduled_date: date) }
  # 指定された年月のスケジュールを範囲で取得
  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(scheduled_date: start_date..end_date)
  }
  # 実施日の降順でスケジュールを取得（新しい日付順）
  scope :recent, -> { order(scheduled_date: :desc) }

  # デリゲート (Delegate)

  # 関連する Plan モデルの属性を 'plan_' プレフィックスを付けて直接呼び出せるようにする
  delegate :name, :description, :category, :products, to: :plan, prefix: true

  # インスタンスメソッド (Instance Methods)


  # 計画 (Plan) から予定売上を取得する
  def expected_revenue
    plan.expected_revenue
  end

  # 実績売上が入力されているかチェック
  def has_actual?
    actual_revenue.present?
  end

  # 売上差異（実績 - 予定）を計算
  def revenue_variance
    return nil unless has_actual?
    actual_revenue - expected_revenue
  end

  # 達成率（実績 / 予定 * 100）を計算
  def achievement_rate
    return nil unless has_actual?
    return 0 if expected_revenue.zero? # 予定売上がゼロの場合は0%とする
    (actual_revenue / expected_revenue * 100).round(1)
  end

  # スケジュール日が今日であるか
  def today?
    scheduled_date == Date.current
  end

  # スケジュール日が過去であるか
  def past?
    scheduled_date < Date.current
  end

  # スケジュール日が未来であるか
  def future?
    scheduled_date > Date.current
  end
end