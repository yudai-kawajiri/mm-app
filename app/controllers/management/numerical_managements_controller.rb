# frozen_string_literal: true

# NumericalManagementsController
#
# 数値管理機能を提供するコントローラー
#
# 機能:
#   - 月次予算、日別目標、売上実績の管理
#   - カレンダー形式での表示と一括更新機能
#   - 月次予測データの表示
#   - 達成率の可視化
#   - 数値入力のサニタイズ処理（NumericSanitizer）
#
# ルート:
#   GET    /numerical_managements          #index   - 月選択画面
#   GET    /numerical_managements/calendar #calendar - カレンダー表示
#   PATCH  /numerical_managements/:id      #update_daily_target - 日別目標更新
#   POST   /numerical_managements/bulk_update #bulk_update - 一括更新
class Management::NumericalManagementsController < ApplicationController
  include NumericSanitizer

  # 認証必須
  before_action :authenticate_user!

  # 月選択画面
  #
  # 数値管理のトップページ
  # 月を選択してカレンダー表示に遷移
  #
  # @return [void]
  def index
    @selected_date = Date.current

    @forecast_data = {
      target_amount: 0,
      actual_amount: 0,
      achievement_rate: 0
    }
    @monthly_budget = nil
    @daily_data = []
    @daily_targets = {}
  end

  # カレンダー表示
  #
  # 指定された年月のカレンダーを表示
  # 日別の売上実績、予算、目標、達成率を一覧表示
  #
  # @return [void]
  def calendar
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month

    calendar_data = CalendarDataBuilderService.new(current_user, @year, @month).build
    @daily_data = calendar_data[:daily_data]
    @monthly_budget = calendar_data[:monthly_budget]
    @daily_targets = calendar_data[:daily_targets]

    @forecast = NumericalForecastService.call(current_user, @year, @month)
  end

  # 日別目標を更新
  #
  # 特定の日の目標値を更新
  # 既存レコードがない場合は新規作成
  #
  # @return [void]
  def update_daily_target
    date = Date.parse(params[:daily_target][:date])
    target_value = params[:daily_target][:target]

    daily_target = Management::DailyTarget.find_or_initialize_by(
      user: current_user,
      date: date
    )

    sanitized_value = sanitize_numeric_params(
      { target: target_value },
      with_comma: [:target]
    )[:target]

    if daily_target.update(target: sanitized_value)
      redirect_to management_numerical_managements_path(year: date.year, month: date.month),
                  notice: t('numerical_managements.messages.target_updated')
    else
      redirect_to management_numerical_managements_path(year: date.year, month: date.month),
                  alert: "更新に失敗しました: #{daily_target.errors.full_messages.join(', ')}"
    end
  end

  # 一括更新
  #
  # 月次予算と複数の日別目標を一括で更新
  # トランザクション内で実行され、一つでも失敗すると全体がロールバック
  #
  # @return [void]
  def bulk_update
    year = params[:year].to_i
    month = params[:month].to_i

    service = NumericalDataBulkUpdateService.new(current_user, sanitized_bulk_update_params)

    if service.call
      redirect_to management_numerical_managements_path(year: year, month: month),
                  notice: t('numerical_managements.messages.data_updated')
    else
      redirect_to management_numerical_managements_path(year: year, month: month),
                  alert: "更新に失敗しました: #{service.errors.join(', ')}"
    end
  end

  private

  # 一括更新用のStrong Parameters
  #
  # @return [ActionController::Parameters]
  def bulk_update_params
    params.permit(
      :year,
      :month,
      monthly_budgets: [:budget],
      daily_targets: [:target]
    )
  end

  # 数値パラメータのサニタイズ処理
  #
  # 対象フィールド:
  #   - monthly_budgets[].budget: 月次予算（カンマ区切り対応）
  #   - daily_targets[].target: 日別目標（カンマ区切り対応）
  #
  # @return [Hash]
  def sanitized_bulk_update_params
    params_hash = bulk_update_params.to_h

    if params_hash[:monthly_budgets].present?
      params_hash[:monthly_budgets].each do |_, budget_attrs|
        sanitize_numeric_params(
          budget_attrs,
          with_comma: [:budget]
        )
      end
    end

    if params_hash[:daily_targets].present?
      params_hash[:daily_targets].each do |_, target_attrs|
        sanitize_numeric_params(
          target_attrs,
          with_comma: [:target]
        )
      end
    end

    params_hash
  end
end
