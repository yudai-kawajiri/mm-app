# frozen_string_literal: true

#
# CalendarDataBuilderService
#
# 数値管理カレンダーのデータ構築を処理するサービスクラス
#
# @description
#   指定された年月の日別データ、予算、目標、達成率を計算し、
#   カレンダー表示用のデータ構造を構築します。
#
# @usage
#   service = CalendarDataBuilderService.new(user, year, month)
#   data = service.build
#   # data[:daily_data], data[:monthly_budget], data[:daily_targets]
#
# @features
#   - 月間カレンダーデータの生成（1日〜末日）
#   - 日別売上実績の集計
#   - 日別予算・目標の取得
#   - 日次・月次達成率の計算
#   - 月次予測データの統合
#
class CalendarDataBuilderService
  #
  # サービスの初期化
  #
  # @param user [User] 現在のユーザー
  # @param year [Integer] 対象年（例: 2024）
  # @param month [Integer] 対象月（1-12）
  #
  # @example
  #   service = CalendarDataBuilderService.new(current_user, 2024, 11)
  #   data = service.build
  #
  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month
  end

  #
  # カレンダーデータを構築
  #
  # @return [Hash] 日別データ、月次予算、日別目標を含むハッシュ
  #
  # @option return [Array<Hash>] :daily_data 日別データ配列
  #   - date: 日付
  #   - actual: 実績売上
  #   - budget: 予算
  #   - target: 目標
  #   - achievement_rate: 達成率（%）
  #   - is_today: 今日かどうか
  #   - is_future: 未来の日付かどうか
  # @option return [MonthlyBudget, nil] :monthly_budget 月次予算オブジェクト
  # @option return [Hash] :daily_targets 日別目標のハッシュ（日付 => DailyTarget）
  #
  # @example
  #   data = service.build
  #   data[:daily_data].each do |day|
  #     puts "#{day[:date]}: #{day[:actual]}円 (#{day[:achievement_rate]}%)"
  #   end
  #
  def build
    {
      daily_data: build_daily_array,
      monthly_budget: fetch_monthly_budget,
      daily_targets: fetch_daily_targets_hash
    }
  end

  private

  #
  # 日別データ配列を構築
  #
  # @return [Array<Hash>] 1日〜末日までの日別データ
  #
  # @note
  #   - DailyDataServiceで実績データを取得
  #   - 予算・目標と結合して達成率を計算
  #   - 今日・未来フラグを付与
  #
  def build_daily_array
    daily_data_hash = fetch_daily_data_hash
    monthly_budget = fetch_monthly_budget
    daily_targets_hash = fetch_daily_targets_hash

    (@start_date..@end_date).map do |date|
      actual = daily_data_hash[date]&.dig(:actual) || 0
      budget = calculate_daily_budget(date, monthly_budget)
      target = daily_targets_hash[date]&.target || 0

      {
        date: date,
        actual: actual,
        budget: budget,
        target: target,
        achievement_rate: calculate_achievement_rate(actual, budget),
        is_today: date == Date.today,
        is_future: date > Date.today
      }
    end
  end

  #
  # DailyDataServiceから日別実績データを取得
  #
  # @return [Hash] 日付をキーとする実績データのハッシュ
  #
  # @note
  #   DailyDataService.call(user, year, month) の戻り値を利用
  #
  def fetch_daily_data_hash
    DailyDataService.call(@user, @year, @month)
  end

  #
  # 月次予算を取得
  #
  # @return [MonthlyBudget, nil] 該当月の予算オブジェクト
  #
  # @note
  #   存在しない場合はnilを返す
  #
  def fetch_monthly_budget
    MonthlyBudget.find_by(
      user: @user,
      year: @year,
      month: @month
    )
  end

  #
  # 日別目標をハッシュで取得
  #
  # @return [Hash] 日付をキーとするDailyTargetのハッシュ
  #
  # @example
  #   { Date.new(2024,11,1) => #<DailyTarget:0x...>, ... }
  #
  def fetch_daily_targets_hash
    DailyTarget
      .where(user: @user, date: @start_date..@end_date)
      .index_by(&:date)
  end

  #
  # 日別予算を計算
  #
  # @param date [Date] 対象日
  # @param monthly_budget [MonthlyBudget, nil] 月次予算
  # @return [Integer] 日別予算（円）
  #
  # @note
  #   月次予算が存在する場合は月の日数で均等割り
  #   存在しない場合は0を返す
  #
  def calculate_daily_budget(date, monthly_budget)
    return 0 unless monthly_budget&.budget

    (monthly_budget.budget.to_f / @end_date.day).round
  end

  #
  # 達成率を計算
  #
  # @param actual [Numeric] 実績値
  # @param budget [Numeric] 予算値
  # @return [Float, nil] 達成率（%）、予算が0の場合はnil
  #
  # @example
  #   calculate_achievement_rate(8000, 10000)  # => 80.0
  #   calculate_achievement_rate(12000, 10000) # => 120.0
  #   calculate_achievement_rate(5000, 0)      # => nil
  #
  def calculate_achievement_rate(actual, budget)
    return nil if budget.zero?

    ((actual.to_f / budget) * 100).round(1)
  end
end
