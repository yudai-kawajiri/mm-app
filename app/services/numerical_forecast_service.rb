# frozen_string_literal: true

##
# 月次予算に対する予測データを計算するサービス
#
# 現在の実績データから月末予測値を算出し、予算達成に向けた
# アクションプランを提供します。
#
# @example 基本的な使用方法
#   service = NumericalForecastService.new(year: 2024, month: 12)
#   forecast_data = service.calculate
#
class NumericalForecastService
  # パーセント計算用の係数（比率を百分率に変換）
  PERCENTAGE_MULTIPLIER = 100

  # 達成率の小数点以下精度
  RATE_PRECISION = 1

  # 金額の小数点以下精度（整数丸め）
  AMOUNT_PRECISION = 0

  attr_reader :year, :month

  ##
  # @param year [Integer, String] 対象年
  # @param month [Integer, String] 対象月
  def initialize(year:, month:)
    @year = year.to_i
    @month = month.to_i
  end

  ##
  # 予測データを計算して返す
  #
  # @return [Hash] 予測データのハッシュ
  #   - target_amount: 月次予算
  #   - actual_amount: 実績売上
  #   - planned_amount: 月間計画売上
  #   - forecast_amount: 月末予測売上
  #   - achievement_rate: 予測達成率(%)
  #   - forecast_diff: 予算差
  #   - daily_achievement_rate: 日別予算達成率(%)
  #   - remaining_days: 残り日数
  #   - required_additional: 必要追加高
  #   - daily_required: 推奨日次目標
  #   - current_daily_average: 現在の1日平均実績
  #   - daily_target_diff: 目標との差
  def calculate
    budget = find_monthly_budget
    return default_data unless budget

    # 月の範囲を取得
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month
    today = Date.current

    # 昨日までの日付範囲（今日が月内の場合のみ）
    yesterday = today - 1.day
    past_end = [ yesterday, end_date ].min

    # データ取得
    target = budget.target_amount || 0

    # 見切率の取得
    forecast_discount_rate = budget.forecast_discount_rate || 0
    target_discount_rate = budget.target_discount_rate || 0

    # 月全体のスケジュールを取得
    all_schedules = Planning::PlanSchedule
                  .where(scheduled_date: start_date..end_date)

    # 実績が入力されているものの合計
    actual_confirmed = all_schedules
                        .where.not(actual_revenue: nil)
                        .where("actual_revenue > 0")
                        .sum(:actual_revenue) || 0

    # 実績未入力のスケジュールの計画高を集計
    unconfirmed_schedules = all_schedules.select do |ps|
      ps.actual_revenue.nil? || ps.actual_revenue.zero?
    end
    unconfirmed_planned_total = unconfirmed_schedules.sum { |ps| ps.current_planned_revenue }

    # 月全体の計画高（月間計画売上カード用）
    total_planned_amount = all_schedules.sum { |ps| ps.current_planned_revenue }

    # 月末予測売上 = 確定実績 + 実績未入力の計画高 × (1 - 予測見切率/100)
    discount_multiplier = 1 - (forecast_discount_rate / PERCENTAGE_MULTIPLIER)
    adjusted_planned = (unconfirmed_planned_total * discount_multiplier).round(AMOUNT_PRECISION)
    forecast = actual_confirmed + adjusted_planned

    # 予算差
    diff = forecast - target

    # 予測達成率（月末予測 ÷ 月次予算）
    forecast_achievement_rate = target.positive? ? ((forecast.to_f / target) * PERCENTAGE_MULTIPLIER).round(RATE_PRECISION) : 0.0

    # 昨日までの日別予算の合計
    past_target = Management::DailyTarget
                .where(target_date: start_date..past_end)
                .sum(:target_amount) || 0

    # 昨日までの日別予算達成率
    daily_achievement_rate = past_target.positive? ? ((actual_confirmed.to_f / past_target) * PERCENTAGE_MULTIPLIER).round(RATE_PRECISION) : 0.0

    # 残り日数（今日から月末まで）
    remaining_days = if today <= end_date && today >= start_date
                        (end_date - today).to_i + 1
    else
                        0
    end

    # 必要追加高（予算に達していない場合のみ）
    required_additional = diff < 0 ? diff.abs : 0

    # 推奨日次目標 = (必要追加高 ÷ 残り日数) ÷ (1 - 目標見切率/100)
    daily_required = if remaining_days > 0 && required_additional > 0
                        target_discount_multiplier = 1 - (target_discount_rate / PERCENTAGE_MULTIPLIER)
                        if target_discount_multiplier > 0
                          ((required_additional.to_f / remaining_days) / target_discount_multiplier).round(AMOUNT_PRECISION)
                        else
                          0
                        end
    else
                        0
    end

    # 現在の1日平均実績
    elapsed_days = if today >= start_date && today <= end_date
                      (today - start_date).to_i
    elsif today > end_date
                      (end_date - start_date).to_i + 1
    else
                      0
    end
    current_daily_average = elapsed_days > 0 ? (actual_confirmed.to_f / elapsed_days).round(AMOUNT_PRECISION) : 0

    # 目標との差（推奨日次目標 - 現在の1日平均）
    daily_target_diff = daily_required - current_daily_average

    {
      # 月末予測カード用
      target_amount: target,
      actual_amount: actual_confirmed,
      planned_amount: total_planned_amount,
      forecast_amount: forecast,
      achievement_rate: forecast_achievement_rate,
      forecast_diff: diff,

      # 日別予算達成率（参考用）
      daily_achievement_rate: daily_achievement_rate,

      # アクションプランカード用
      remaining_days: remaining_days,
      required_additional: required_additional,
      daily_required: daily_required,
      current_daily_average: current_daily_average,
      daily_target_diff: daily_target_diff
    }
  end

  private

  ##
  # 月次予算を取得
  #
  # @return [MonthlyBudget, nil] 月次予算レコード
  def find_monthly_budget
    budget_month = Date.new(@year, @month, 1)
    Management::MonthlyBudget.find_by(budget_month: budget_month)
  end

  ##
  # デフォルトの予測データ
  #
  # @return [Hash] 空の予測データ
  def default_data
    {
      target_amount: 0,
      actual_amount: 0,
      planned_amount: 0,
      forecast_amount: 0,
      achievement_rate: 0.0,
      forecast_diff: 0,
      daily_achievement_rate: 0.0,
      remaining_days: 0,
      required_additional: 0,
      daily_required: 0,
      current_daily_average: 0,
      daily_target_diff: 0
    }
  end
end
