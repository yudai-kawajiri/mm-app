class PlanSchedule < ApplicationRecord
  include StripCommas
  strip_commas_from :planned_revenue, :actual_revenue

  # PaperTrailで変更履歴を記録
  has_paper_trail

  # 関連付け (Association)
  belongs_to :plan
  belongs_to :user

  # バリデーション (Validation)
  validates :scheduled_date, presence: true, uniqueness: { scope: :plan_id }
  validates :status, presence: true
  validates :actual_revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # スケジュールの現在の状態を定義
  enum :status, { scheduled: 0, completed: 1, cancelled: 2 }

  # ★★★ 修正: actual_revenue 入力時に planned_revenue を固定 ★★★
  before_save :freeze_planned_revenue_on_actual_input

  # スコープ (Scope)
  scope :for_date, ->(date) { where(scheduled_date: date) }
  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(scheduled_date: start_date..end_date)
  }
  scope :recent, -> { order(scheduled_date: :desc) }

  # クラスメソッド (Class Methods)
  def self.material_requirements_for_date(user, date)
    schedules = where(user: user, scheduled_date: date)
                .includes(plan: { plan_products: { product: { product_materials: [:material, :unit] } } })

    requirements = {}

    schedules.each do |schedule|
      schedule.plan.aggregated_material_requirements.each do |req|
        material_id = req[:material_id]

        if requirements[material_id]
          requirements[material_id][:total_quantity] += req[:total_quantity]
          requirements[material_id][:total_weight] += req[:total_weight]
          requirements[material_id][:required_order_quantity] += req[:required_order_quantity]
          requirements[material_id][:plans] ||= []
          requirements[material_id][:plans] << schedule.plan.name
        else
          requirements[material_id] = req.dup
          requirements[material_id][:plans] = [schedule.plan.name]
        end
      end
    end

    requirements.values.sort_by { |req| req[:material_name] }
  end

  # デリゲート (Delegate)
  delegate :name, :description, :category, :products, to: :plan, prefix: true

  # インスタンスメソッド (Instance Methods)

  # ★★★ 修正: 実績の有無だけで判定（planned_revenue の値は見ない）★★★
  def current_planned_revenue
    if actual_revenue.present?
      # 実績入力済み → freeze されている planned_revenue を使用
      planned_revenue || plan&.expected_revenue || 0
    else
      # 実績未入力 → 常に Plan の最新値を動的参照
      plan&.expected_revenue || 0
    end
  end

  # 計画 (Plan) から予定売上を取得する
  def expected_revenue
    current_planned_revenue
  end

  # 実績売上が入力されているかチェック
  def has_actual?
    actual_revenue.present?
  end

  # 売上差異（実績 - 予定）を計算
  def revenue_variance
    (actual_revenue || 0) - expected_revenue
  end

  alias_method :variance, :revenue_variance

  # 達成率（実績 / 予定 * 100）を計算
  def achievement_rate
    return nil unless has_actual?
    return 0 if expected_revenue.zero?
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

  private

  # ★★★ actual_revenue が nil → 値あり に変化したときに planned_revenue を保存 ★★★
  def freeze_planned_revenue_on_actual_input
    if actual_revenue_changed? && actual_revenue.present? && actual_revenue_was.nil?
      self.planned_revenue = plan&.expected_revenue || 0
      Rails.logger.info "PlanSchedule##{id || 'new'}: planned_revenue を固定 → #{self.planned_revenue}"
    end
  end
end
