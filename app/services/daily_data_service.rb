# frozen_string_literal: true

# DailyDataService
#
# 日別データ（目標・実績・計画）を計算するサービス
#
# 使用例:
#   service = DailyDataService.new(current_user, 2024, 12)
#   daily_data = service.call
#
# 機能:
#   - 月の全日付の日別データを生成
#   - 目標・実績・計画・予測・達成率を計算
#   - N+1問題対策（事前ロード）
class DailyDataService
  attr_reader :user, :year, :month

  # @param user [User] 対象ユーザー
  # @param year [Integer, String] 対象年
  # @param month [Integer, String] 対象月
  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_budget
    load_data_for_month
  end

  # 日別データの配列を返す
  #
  # @return [Array<Hash>] 日別データの配列
  #   - date: 日付
  #   - target: 日別目標
  #   - actual: 実績売上
  #   - plan: 計画売上
  #   - forecast: 予測（実績 or 計画）
  #   - diff: 差異（予測 - 目標）
  #   - achievement_rate: 達成率
  def call
    return [] unless @budget

    # 月の全日付を取得
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    (start_date..end_date).map do |date|
      calculate_daily_data(date)
    end
  end

  private

  # 月次予算を取得
  #
  # @return [MonthlyBudget, nil] 月次予算
  def find_budget
    budget_month = Date.new(@year, @month, 1)
    MonthlyBudget.find_by(
      user: @user,
      budget_month: budget_month
    )
  end

  # データを事前ロード（N+1問題対策）
  #
  # @return [void]
  def load_data_for_month
    return unless @budget

    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    # 日別目標を事前ロード
    @daily_targets = @budget.daily_targets
                            .where(target_date: start_date..end_date)
                            .to_a

    # 計画スケジュールを事前ロード
    @plan_schedules = @user.plan_schedules
                           .where(scheduled_date: start_date..end_date)
                           .includes(:plan)
                           .to_a
  end

  # 日別データを計算
  #
  # @param date [Date] 対象日
  # @return [Hash] 日別データ
  def calculate_daily_data(date)
    target = daily_target(date)
    actual = daily_actual(date)
    plan = daily_plan(date)
    forecast = actual.positive? ? actual : plan
    diff = forecast - target
    achievement_rate = target.positive? ? (forecast / target * 100).round(1) : 0

    {
      date: date,
      target: target,
      actual: actual,
      plan: plan,
      forecast: forecast,
      diff: diff,
      achievement_rate: achievement_rate
    }
  end

  # 日別目標を取得（メモリ上検索）
  #
  # @param date [Date] 対象日
  # @return [Integer] 日別目標金額
  def daily_target(date)
    daily_targets = @daily_targets || []
    daily_target = daily_targets.find { |dt| dt.target_date == date }
    daily_target&.target_amount || 0
  end

  # 日別実績を取得（メモリ上検索）
  #
  # @param date [Date] 対象日
  # @return [Integer] 実績売上
  def daily_actual(date)
    plan_schedules_list = @plan_schedules || []
    plan_schedules = plan_schedules_list.select { |ps| ps.scheduled_date == date }
    plan_schedules.sum { |ps| ps.actual_revenue || 0 }
  end

  # 日別計画を取得（メモリ上検索）
  #
  # @param date [Date] 対象日
  # @return [Integer] 計画売上
  def daily_plan(date)
    plan_schedules_list = @plan_schedules || []
    plan_schedules = plan_schedules_list.select { |ps| ps.scheduled_date == date }
    plan_schedules.sum { |ps| ps.planned_revenue || 0 }
  end
end
