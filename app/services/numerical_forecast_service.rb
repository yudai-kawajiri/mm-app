# frozen_string_literal: true

# NumericalForecastService
#
# 月次予算に対する予測データを計算するサービス
#
# 使用例:
#   service = NumericalForecastService.new(user: current_user, year: 2024, month: 12)
#   forecast_data = service.calculate
#
# 機能:
#   - 月末予測売上の計算
#   - 予算達成率の算出
#   - 日別目標との比較
#   - アクションプランの提案（推奨日次目標）
class NumericalForecastService
  attr_reader :user, :year, :month

  # @param user [User] 対象ユーザー
  # @param year [Integer, String] 対象年
  # @param month [Integer, String] 対象月
  def initialize(user:, year:, month:)
    @user = user
    @year = year.to_i
    @month = month.to_i
  end

  # 予測データを計算
  #
  # @return [Hash] 予測データ
  #   - target_amount: 月次予算
  #   - actual_amount: 実績売上
  #   - planned_amount: 月間計画売上
  #   - forecast_amount: 月末予測売上
  #   - achievement_rate: 予測達成率
  #   - forecast_diff: 予算差
  #   - budget_achievement_rate: 予算達成率
  #   - daily_achievement_rate: 日別予算達成率
  #   - remaining_days: 残り日数
  #   - required_additional: 必要追加額
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

    # 対象月の「今日」を基準にする
    current_date_in_month = calculate_current_date_in_month(today, start_date, end_date)

    # 昨日の日付を計算
    yesterday_in_month = current_date_in_month - 1.day

    # 実績集計範囲（重要: 月全体から収集）
    past_start = start_date
    past_end = [yesterday_in_month, end_date].min

    # 今日から月末までの範囲
    future_start = [current_date_in_month, start_date].max
    future_end = end_date

    # データ取得
    target = budget.target_amount || 0

    # 実績収集（月全体から、入力済みの実績を全て集計）
    actual = user.plan_schedules
                 .where(scheduled_date: start_date..end_date)
                 .where.not(actual_revenue: nil)
                 .sum(:actual_revenue) || 0

    # 今日から月末までの計画高（実績未入力のもののみ）
    future_schedules = user.plan_schedules
                           .includes(:plan)
                           .where(scheduled_date: future_start..future_end)
                           .where(actual_revenue: nil)

    planned_amount_for_forecast = future_schedules.sum(&:current_planned_revenue)

    # 月全体の計画高
    all_schedules = user.plan_schedules
                        .includes(:plan)
                        .where(scheduled_date: start_date..end_date)

    total_planned_amount = all_schedules.sum(&:current_planned_revenue)

    # 月末予測売上
    forecast = actual + planned_amount_for_forecast

    # 予算差
    diff = forecast - target

    # 予測達成率
    forecast_achievement_rate = calculate_rate(forecast, target)

    # 予算達成率
    budget_achievement_rate = calculate_rate(actual, target)

    # 昨日までの日別予算の合計
    past_target = if past_start <= past_end
                    user.daily_targets
                        .where(target_date: past_start..past_end)
                        .sum(:target_amount) || 0
                  else
                    0
                  end

    # 昨日までの日別予算達成率
    daily_achievement_rate = calculate_rate(actual, past_target)

    # 残り日数
    remaining_days = calculate_remaining_days(current_date_in_month, start_date, end_date)

    # 必要追加額
    required_additional = diff.negative? ? diff.abs : 0

    # 推奨日次目標
    daily_required = if remaining_days.positive? && required_additional.positive?
                       (required_additional.to_f / remaining_days).round
                     else
                       0
                     end

    # 現在の1日平均実績
    elapsed_days = calculate_elapsed_days(current_date_in_month, start_date, end_date)
    current_daily_average = elapsed_days.positive? ? (actual.to_f / elapsed_days).round : 0

    # 目標との差
    daily_target_diff = daily_required - current_daily_average

    {
      # 月末予測カード用
      target_amount: target,
      actual_amount: actual,
      planned_amount: total_planned_amount,
      forecast_amount: forecast,
      achievement_rate: forecast_achievement_rate,
      forecast_diff: diff,

      # 予算達成率（画面の「予算達成率」カード用）
      budget_achievement_rate: budget_achievement_rate,

      # 日別予算達成率
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

  # 月次予算を取得
  #
  # @return [MonthlyBudget, nil] 月次予算
  def find_monthly_budget
    budget_month = Date.new(@year, @month, 1)
    user.monthly_budgets.find_by(budget_month: budget_month)
  end

  # デフォルトデータを返却（予算未設定時）
  #
  # @return [Hash] ゼロ値で初期化されたデータ
  def default_data
    {
      target_amount: 0,
      actual_amount: 0,
      planned_amount: 0,
      forecast_amount: 0,
      achievement_rate: 0.0,
      forecast_diff: 0,
      budget_achievement_rate: 0.0,
      daily_achievement_rate: 0.0,
      remaining_days: 0,
      required_additional: 0,
      daily_required: 0,
      current_daily_average: 0,
      daily_target_diff: 0
    }
  end

  # 対象月の現在日を計算
  #
  # @param today [Date] 今日の日付
  # @param start_date [Date] 月初日
  # @param end_date [Date] 月末日
  # @return [Date] 対象月の現在日
  def calculate_current_date_in_month(today, start_date, end_date)
    if today < start_date
      start_date  # 未来の月：月初
    elsif today > end_date
      end_date    # 過去の月：月末
    else
      today       # 当月：今日
    end
  end

  # 達成率を計算
  #
  # @param numerator [Numeric] 分子
  # @param denominator [Numeric] 分母
  # @return [Float] 達成率（%）
  def calculate_rate(numerator, denominator)
    denominator.positive? ? ((numerator.to_f / denominator) * 100).round(1) : 0.0
  end

  # 残り日数を計算
  #
  # @param current_date [Date] 現在日
  # @param start_date [Date] 月初日
  # @param end_date [Date] 月末日
  # @return [Integer] 残り日数
  def calculate_remaining_days(current_date, start_date, end_date)
    if current_date <= end_date && current_date >= start_date
      (end_date - current_date).to_i + 1
    else
      0
    end
  end

  # 経過日数を計算
  #
  # @param current_date [Date] 現在日
  # @param start_date [Date] 月初日
  # @param end_date [Date] 月末日
  # @return [Integer] 経過日数
  def calculate_elapsed_days(current_date, start_date, end_date)
    if current_date >= start_date && current_date <= end_date
      (current_date - start_date).to_i
    elsif current_date > end_date
      (end_date - start_date).to_i + 1
    else
      0
    end
  end
end
