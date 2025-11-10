# frozen_string_literal: true

#
# NumericalManagementsController
#
# 数値管理機能を提供するコントローラー
#
# @description
#   月次予算、日別目標、売上実績の管理を行います。
#   カレンダー形式での表示と一括更新機能を提供します。
#
# @routes
#   GET    /numerical_managements          #index   - 月選択画面
#   GET    /numerical_managements/calendar #calendar - カレンダー表示
#   PATCH  /numerical_managements/:id      #update_daily_target - 日別目標更新
#   POST   /numerical_managements/bulk_update #bulk_update - 一括更新
#
# @usage
#   - 月次予算・日別目標の設定
#   - 日別売上実績の確認
#   - 達成率の可視化
#   - 月次予測データの表示
#
class Management::NumericalManagementsController < ApplicationController
  # 認証必須
  before_action :authenticate_user!

  #
  # 月選択画面
  #
  # GET /numerical_managements
  #
  # @description
  #   数値管理のトップページ。月を選択してカレンダー表示に遷移します。
  #
  # @render
  #   app/views/numerical_managements/index.html.erb
  def index
    # デフォルトで今日の日付を設定
    @selected_date = Date.current
    
    # ダミーデータを設定（Viewが期待する形式）
    @forecast_data = {
      target_amount: 0,
      actual_amount: 0,
      achievement_rate: 0
    }
    @monthly_budget = nil
    @daily_data = []
    @daily_targets = {}
  end

  #
  # カレンダー表示
  #
  # GET /numerical_managements/calendar
  #
  # @description
  #   指定された年月のカレンダーを表示します。
  #   日別の売上実績、予算、目標、達成率を一覧表示します。
  #
  # @param [String] year 対象年（デフォルト: 今年）
  # @param [String] month 対象月（デフォルト: 今月）
  #
  # @assigns
  #   @year [Integer] 表示対象年
  #   @month [Integer] 表示対象月
  #   @daily_data [Array<Hash>] 日別データ配列
  #   @monthly_budget [MonthlyBudget, nil] 月次予算
  #   @daily_targets [Hash] 日別目標ハッシュ
  #   @forecast [Hash, nil] 月次予測データ（NumericalForecastService）
  #
  # @render
  #   app/views/numerical_managements/calendar.html.erb
  #
  # @example
  #   GET /numerical_managements/calendar?year=2024&month=11
  #
  def calendar
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month

    # CalendarDataBuilderServiceで日別データを構築
    calendar_data = CalendarDataBuilderService.new(current_user, @year, @month).build
    @daily_data = calendar_data[:daily_data]
    @monthly_budget = calendar_data[:monthly_budget]
    @daily_targets = calendar_data[:daily_targets]

    # 月次予測データを取得（NumericalForecastService）
    @forecast = NumericalForecastService.call(current_user, @year, @month)
  end

  #
  # 日別目標を更新
  #
  # PATCH /numerical_managements/:id
  #
  # @description
  #   特定の日の目標値を更新します。
  #   既存レコードがない場合は新規作成します。
  #
  # @param [String] id DailyTargetのID（新規の場合は"new"）
  #
  # @strong_params
  #   - daily_target [Hash]
  #     - date [String] 日付（YYYY-MM-DD）
  #     - target [String] 目標値（カンマ区切り可）
  #
  # @redirect
  #   成功時: カレンダー画面に戻る（フラッシュメッセージ付き）
  #   失敗時: カレンダー画面に戻る（エラーメッセージ付き）
  #
  # @example リクエスト例
  #   PATCH /numerical_managements/123
  #   {
  #     daily_target: {
  #       date: "2024-11-09",
  #       target: "5,000"
  #     }
  #   }
  #
  def update_daily_target
    date = Date.parse(params[:daily_target][:date])
    target_value = params[:daily_target][:target]

    # 既存レコードを検索または新規作成
    daily_target = Management::DailyTarget.find_or_initialize_by(
      user: current_user,
      date: date
    )

    # 目標値を更新（StripCommas concernが自動でカンマ除去）
    if daily_target.update(target: target_value)
      redirect_to calendar_numerical_managements_path(year: date.year, month: date.month),
                  notice: t('numerical_managements.messages.target_updated')
    else
      redirect_to calendar_numerical_managements_path(year: date.year, month: date.month),
                  alert: "更新に失敗しました: #{daily_target.errors.full_messages.join(', ')}"
    end
  end

  #
  # 一括更新
  #
  # POST /numerical_managements/bulk_update
  #
  # @description
  #   月次予算と複数の日別目標を一括で更新します。
  #   トランザクション内で実行され、一つでも失敗すると全体がロールバックされます。
  #
  # @strong_params
  #   - year [String] 対象年
  #   - month [String] 対象月
  #   - monthly_budgets [Hash] MonthlyBudgetの更新データ（id => { budget: "100,000" }）
  #   - daily_targets [Hash] DailyTargetの更新データ（id => { target: "5,000" }）
  #
  # @redirect
  #   成功時: カレンダー画面に戻る（成功メッセージ）
  #   失敗時: カレンダー画面に戻る（エラーメッセージ）
  #
  # @example リクエスト例
  #   POST /numerical_managements/bulk_update
  #   {
  #     year: "2024",
  #     month: "11",
  #     monthly_budgets: {
  #       "1" => { budget: "300,000" }
  #     },
  #     daily_targets: {
  #       "10" => { target: "10,000" },
  #       "11" => { target: "12,000" }
  #     }
  #   }
  #
  def bulk_update
    year = params[:year].to_i
    month = params[:month].to_i

    # NumericalDataBulkUpdateServiceで一括更新を実行
    service = NumericalDataBulkUpdateService.new(current_user, bulk_update_params)

    if service.call
      redirect_to calendar_numerical_managements_path(year: year, month: month),
                  notice: t('numerical_managements.messages.data_updated')
    else
      redirect_to calendar_numerical_managements_path(year: year, month: month),
                  alert: "更新に失敗しました: #{service.errors.join(', ')}"
    end
  end

  private

  #
  # 一括更新用のStrong Parameters
  #
  # @return [ActionController::Parameters]
  #
  # @note
  #   monthly_budgets, daily_targetsのネストしたハッシュを許可
  #
  def bulk_update_params
    params.permit(
      :year,
      :month,
      monthly_budgets: [:budget],
      daily_targets: [:target]
    )
  end
end
