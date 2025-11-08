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

    # ★★★ 修正: 対象月の「今日」を基準にする ★★★
    current_date_in_month = if today < start_date
                              start_date  # 未来の月：月初
                            elsif today > end_date
                              end_date    # 過去の月：月末
                            else
                              today       # 当月：今日
                            end

    # ★★★ 修正: 昨日の日付を計算 ★★★
    yesterday_in_month = current_date_in_month - 1.day

    # ★★★ 重要な修正: 実績は常に月全体から収集（入力済みデータを逃さない）★★★
    # 昨日が月初より前でも、月内に実績があれば集計する
    past_start = start_date
    past_end = if yesterday_in_month < start_date
                 start_date - 1.day  # 月初より前なので実質的に範囲なし
               else
                 [yesterday_in_month, end_date].min
               end

    # 今日から月末までの日付範囲
    future_start = [current_date_in_month, start_date].max
    future_end = end_date

    # データ取得
    target = budget.target_amount || 0

    # ★★★ 修正: 実績収集を月全体から行う（日付に関係なく、入力済みの実績を全て集計）★★★
    actual = user.plan_schedules
                 .where(scheduled_date: start_date..end_date)
                 .where.not(actual_revenue: nil)
                 .sum(:actual_revenue) || 0

    # 今日から月末までの計画高（実績未入力のもののみ）
    future_schedules = user.plan_schedules
                           .includes(:plan)
                           .where(scheduled_date: future_start..future_end)
                           .where(actual_revenue: nil)

    planned_amount_for_forecast = future_schedules.sum { |ps| ps.current_planned_revenue }

    # 月全体の計画高（月間計画売上カード用）
    all_schedules = user.plan_schedules
                        .includes(:plan)
                        .where(scheduled_date: start_date..end_date)

    total_planned_amount = all_schedules.sum { |ps| ps.current_planned_revenue }

    # 月末予測売上 = 実績 + 今日からの計画高
    forecast = actual + planned_amount_for_forecast

    # 予算差
    diff = forecast - target

    # 予測達成率（月末予測 ÷ 月次予算）
    forecast_achievement_rate = target.positive? ? ((forecast.to_f / target) * 100).round(1) : 0.0

    # ★★★ 予算達成率（実績 ÷ 月次予算）★★★
    budget_achievement_rate = target.positive? ? ((actual.to_f / target) * 100).round(1) : 0.0

    # 昨日までの日別予算の合計（実際にデータがある範囲のみ）
    past_target = if past_start <= past_end
                    user.daily_targets
                        .where(target_date: past_start..past_end)
                        .sum(:target_amount) || 0
                  else
                    0
                  end

    # 昨日までの日別予算達成率
    daily_achievement_rate = past_target.positive? ? ((actual.to_f / past_target) * 100).round(1) : 0.0

    # 残り日数（今日から月末まで）
    remaining_days = if current_date_in_month <= end_date && current_date_in_month >= start_date
                       (end_date - current_date_in_month).to_i + 1
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
    elapsed_days = if current_date_in_month >= start_date && current_date_in_month <= end_date
                     (current_date_in_month - start_date).to_i
                   elsif current_date_in_month > end_date
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
      planned_amount: total_planned_amount,
      forecast_amount: forecast,
      achievement_rate: forecast_achievement_rate,
      forecast_diff: diff,

      # ★★★ 予算達成率（画面の「予算達成率」カード用）★★★
      budget_achievement_rate: budget_achievement_rate,

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
      budget_achievement_rate: 0.0,
      daily_achievement_rate: 0.0,
      remaining_days: 0,
      required_additional: 0,
      daily_required: 0,
      current_daily_average: 0,
      daily_target_diff: 0
    }
  end
end
