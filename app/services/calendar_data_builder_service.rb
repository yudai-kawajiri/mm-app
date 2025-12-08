# frozen_string_literal: true

#
# CalendarDataBuilderService
#
# 数値管理カレンダーのデータ構築を処理するサービスクラス
#
# @description
#   指定された年月の日別データ、予算、目標、達成率、計画スケジュールを計算し、
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
#   - 日別計画スケジュールの取得
#   - 日次・月次達成率の計算
#   - 月次予測データの統合
#
class CalendarDataBuilderService
  #
  # サービスの初期化
  #
  # @param year [Integer] 対象年（例: 2024）
  # @param month [Integer] 対象月（1-12）
  #
  # @example
  #   service = CalendarDataBuilderService.new(current_user, 2024, 11)
  #   data = service.build
  #
  def initialize(year, month)
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
  #   - planned: 計画高
  #   - plan_schedules: 計画スケジュール配列
  #   - achievement_rate: 達成率（%）
  #   - diff: 予算差
  #   - is_today: 今日かどうか
  #   - is_future: 未来の日付かどうか
  # @option return [Management::MonthlyBudget, nil] :monthly_budget 月次予算オブジェクト
  # @option return [Hash] :daily_targets 日別目標のハッシュ（日付 => Management::DailyTarget）
  #
  # @example
  #   data = service.build
  #   data[:daily_data].each do |day|
  #     puts "#{day[:date]}: 実績#{day[:actual]}円 計画#{day[:planned]}円 (#{day[:achievement_rate]}%)"
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
  # @description
  #   - DailyDataServiceで実績・計画データを取得
  #   - 計画スケジュールを追加
  #   - 予算・目標と結合して達成率を計算
  #   - 今日・未来フラグを付与
  #
  def build_daily_array
    daily_data_service = DailyDataService.new(@year, @month)
    daily_data_list = daily_data_service.call
    plan_schedules_hash = fetch_plan_schedules_hash

    daily_data_list.map do |day_data|
      date = day_data[:date]
      day_schedules = plan_schedules_hash[date] || []

      {
        date: date,
        actual: day_data[:actual] || 0,
        budget: day_data[:target] || 0,
        target: day_data[:target] || 0,
        planned: day_data[:plan] || 0,
        plan_schedules: day_schedules,
        achievement_rate: day_data[:achievement_rate],
        diff: day_data[:diff] || 0,
        is_today: date == Date.today,
        is_future: date > Date.today
      }
    end
  end

  #
  # 月次予算を取得
  #
  # @return [Management::MonthlyBudget, nil] 該当月の予算オブジェクト
  #
  # @description
  #   Management名前空間に対応
  #   budget_monthカラムを使用
  #
  def fetch_monthly_budget
    Management::MonthlyBudget.find_by(
      budget_month: Date.new(@year, @month, 1)
    )
  end

  #
  # 日別目標をハッシュで取得
  #
  # @return [Hash] 日（1-31）をキーとするDailyTargetのハッシュ
  #
  # @description
  #   Management名前空間に対応
  #   target_dateカラムを使用
  #
  # @example
  #   { 1 => #<Management::DailyTarget:0x...>, 2 => ... }
  #
  def fetch_daily_targets_hash
    Management::DailyTarget
      .where(target_date: @start_date..@end_date)
      .index_by { |dt| dt.target_date.day }
  end

  #
  # 計画スケジュールをハッシュで取得
  #
  # @return [Hash] 日付をキーとする計画スケジュール配列のハッシュ
  #
  # @description
  #   Planning::PlanScheduleから該当月のデータを取得
  #   planとcategoryをeager loadで効率化
  #
  # @example
  #   {
  #     Date.new(2024,11,1) => [#<Planning::PlanSchedule:0x...>],
  #     Date.new(2024,11,2) => [#<Planning::PlanSchedule:0x...>],
  #     ...
  #   }
  #
  def fetch_plan_schedules_hash
    Planning::PlanSchedule
      .where(scheduled_date: @start_date..@end_date)
      .includes(plan: :category)
      .group_by(&:scheduled_date)
  end
end
