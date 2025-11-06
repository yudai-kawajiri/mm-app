class PlanSchedule < ApplicationRecord
  include StripCommas
  strip_commas_from :planned_revenue, :actual_revenue

  # PaperTrailで変更履歴を記録
  has_paper_trail

  # 関連付け (Association)
  belongs_to :plan
  belongs_to :user

  # バリデーション (Validation)
  # 実施日は必須入力
  # uniqueness: { scope: :plan_id } により、同一のPlanに対し同じ日にスケジュールを重複作成できないようにする
  validates :scheduled_date, presence: true, uniqueness: { scope: :plan_id }
  # ステータスは必須
  validates :status, presence: true
  # 実績売上は0以上の数値のみ許可（nilも許可し、未入力に対応）
  validates :actual_revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

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

  # クラスメソッド (Class Methods)

  # 特定日付の全計画から原材料を集計
  def self.material_requirements_for_date(user, date)
    schedules = where(user: user, scheduled_date: date)
                .includes(plan: { plan_products: { product: { product_materials: [:material, :unit] } } })

    requirements = {}

    schedules.each do |schedule|
      schedule.plan.aggregated_material_requirements.each do |req|
        material_id = req[:material_id]

        if requirements[material_id]
          # 既存の原材料に加算
          requirements[material_id][:total_quantity] += req[:total_quantity]
          requirements[material_id][:total_weight] += req[:total_weight]
          requirements[material_id][:required_order_quantity] += req[:required_order_quantity]
          requirements[material_id][:plans] ||= []
          requirements[material_id][:plans] << schedule.plan.name
        else
          # 新しい原材料
          requirements[material_id] = req.dup
          requirements[material_id][:plans] = [schedule.plan.name]
        end
      end
    end

    requirements.values.sort_by { |req| req[:material_name] }
  end

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
  # 修正: nilを返さず、実績がない場合は 0 - expected_revenue を返す
  def revenue_variance
    (actual_revenue || 0) - expected_revenue
  end

  # variance エイリアス（ビューで使用）
  alias_method :variance, :revenue_variance

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
