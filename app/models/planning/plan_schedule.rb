# frozen_string_literal: true

# PlanSchedule
#
# 計画スケジュールモデル - 計画の実施日と実績を管理
#
# 使用例:
#   PlanSchedule.create(plan_id: 1, scheduled_date: Date.today, status: :scheduled)
#   PlanSchedule.for_month(2024, 12)
#   schedule.achievement_rate
class Planning::PlanSchedule < ApplicationRecord
  # カンマ削除機能
  include StripCommas
  strip_commas_from :planned_revenue, :actual_revenue

  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include UserAssociatable

  # 計画との関連
  belongs_to :plan, class_name: 'Resources::Plan'

  # バリデーション
  validates :scheduled_date, presence: true, uniqueness: { scope: :plan_id }
  validates :status, presence: true
  validates :actual_revenue, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # スケジュールの現在の状態を定義
  enum :status, { scheduled: 0, completed: 1, cancelled: 2 }

  # actual_revenue 入力時に planned_revenue を固定
  before_save :freeze_planned_revenue_on_actual_input

  # 指定日のスケジュールを取得
  #
  # @param date [Date] 対象日
  # @return [ActiveRecord::Relation] 検索結果
  scope :for_date, ->(date) { where(scheduled_date: date) }

  # 指定月のスケジュールを取得
  #
  # @param year [Integer] 年
  # @param month [Integer] 月
  # @return [ActiveRecord::Relation] 検索結果
  scope :for_month, lambda { |year, month|
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(scheduled_date: start_date..end_date)
  }

  # 日付順で取得（降順）
  scope :recent, -> { order(scheduled_date: :desc) }

  # 指定日の材料必要量を集計
  #
  # @param user [User] ユーザー
  # @param date [Date] 対象日
  # @return [Array<Hash>] 材料必要量の配列
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

  # 計画の属性を委譲
  delegate :name, :description, :category, :products, to: :plan, prefix: true

  # 現在の計画売上を取得
  #
  # 実績入力済みの場合は固定された planned_revenue を使用
  # 実績未入力の場合は計画の最新値を動的参照
  #
  # @return [Integer] 計画売上
  def current_planned_revenue
    if actual_revenue.present?
      # 実績入力済み → 固定された planned_revenue を使用
      planned_revenue || plan&.expected_revenue || 0
    else
      # 実績未入力 → 計画の最新値を動的参照
      plan&.expected_revenue || 0
    end
  end

  # 計画から予定売上を取得
  #
  # @return [Integer] 予定売上
  def expected_revenue
    current_planned_revenue
  end

  # 実績売上が入力されているかチェック
  #
  # @return [Boolean] 実績が入力されている場合true
  def has_actual?
    actual_revenue.present?
  end

  # 売上差異（実績 - 予定）を計算
  #
  # @return [Integer] 売上差異
  def revenue_variance
    (actual_revenue || 0) - expected_revenue
  end

  alias_method :variance, :revenue_variance

  # 達成率（実績 / 予定 * 100）を計算
  #
  # @return [Float, nil] 達成率（%）、実績未入力の場合nil
  def achievement_rate
    return nil unless has_actual?
    return 0 if expected_revenue.zero?

    (actual_revenue / expected_revenue * 100).round(1)
  end

  # スケジュール日が今日であるか
  #
  # @return [Boolean]
  def today?
    scheduled_date == Date.current
  end

  # スケジュール日が過去であるか
  #
  # @return [Boolean]
  def past?
    scheduled_date < Date.current
  end

  # スケジュール日が未来であるか
  #
  # @return [Boolean]
  def future?
    scheduled_date > Date.current
  end

  private

  # actual_revenue が nil → 値あり に変化したときに planned_revenue を保存
  def freeze_planned_revenue_on_actual_input
    if actual_revenue_changed? && actual_revenue.present? && actual_revenue_was.nil?
      self.planned_revenue = plan&.expected_revenue || 0
      Rails.logger.info "PlanSchedule##{id || 'new'}: planned_revenue を固定 → #{planned_revenue}"
    end
  end
end
