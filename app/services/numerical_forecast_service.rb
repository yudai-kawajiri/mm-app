# app/services/numerical_forecast_service.rb
class NumericalForecastService
  attr_reader :user, :year, :month

  def initialize(user:, year:, month:)
    @user = user
    @year = year.to_i
    @month = month.to_i
  end

  # メインメソッド：予測データを計算して返す
  def calculate
    budget = find_monthly_budget
    return default_data unless budget

    # 月の範囲を取得
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month
    today = Date.current

    # 昨日までの日付範囲（今日が月内の場合のみ）
    yesterday = today - 1.day
    past_end = [yesterday, end_date].min

    # 今日から月末までの日付範囲
    future_start = [today, start_date].max
    future_end = end_date

    # データ取得
    target = budget.target_amount || 0

    # 昨日までの実績（actual_revenue が入力されているもののみ）
    actual = user.plan_schedules
                 .where(scheduled_date: start_date..past_end)
                 .where.not(actual_revenue: nil)
                 .sum(:actual_revenue) || 0

    # ★★★ 修正1: 今日から月末までの計画高（current_planned_revenue を使用）★★★
    future_schedules = user.plan_schedules
                           .includes(:plan)
                           .where(scheduled_date: future_start..future_end)
                           .where(actual_revenue: nil)

    planned_amount_for_forecast = future_schedules.sum { |ps| ps.current_planned_revenue }

    # ★★★ 修正2: 月全体の計画高（月間計画売上カード用）★★★
    all_schedules = user.plan_schedules
                        .includes(:plan)
                        .where(scheduled_date: start_date..end_date)

    total_planned_amount = all_schedules.sum { |ps| ps.current_planned_revenue }

    # 月末予測売上 = 昨日までの実績 + 今日からの計画高
    forecast = actual + planned_amount_for_forecast

    # 予算差
    diff = forecast - target

    # 予測達成率（月末予測 ÷ 月次予算）
    forecast_achievement_rate = target.positive? ? ((forecast.to_f / target) * 100).round(1) : 0.0

    # 昨日までの日別予算の合計（実際の合計）
    past_target = user.daily_targets
                      .where(target_date: start_date..past_end)
                      .sum(:target_amount) || 0

    # 昨日までの日別予算達成率
    daily_achievement_rate = past_target.positive? ? ((actual.to_f / past_target) * 100).round(1) : 0.0

    # 残り日数（今日から月末まで）
    remaining_days = if today <= end_date && today >= start_date
                       (end_date - today).to_i + 1
                     else
                       0
                     end

    # 必要追加額（予算に達していない場合のみ）
    required_additional = diff < 0 ? diff.abs : 0

    # 推奨日次目標（1日あたり必要額）
    daily_required = if remaining_days > 0 && required_additional > 0
                       (required_additional.to_f / remaining_days).round
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
    current_daily_average = elapsed_days > 0 ? (actual.to_f / elapsed_days).round : 0

    # 目標との差（推奨日次目標 - 現在の1日平均）
    daily_target_diff = daily_required - current_daily_average

    {
      # 月末予測カード用
      target_amount: target,
      actual_amount: actual,
      planned_amount: total_planned_amount,  # ★★★ 月全体の計画高
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

  def find_monthly_budget
    budget_month = Date.new(@year, @month, 1)
    user.monthly_budgets.find_by(budget_month: budget_month)
  end

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
