# frozen_string_literal: true

# 数値管理機能のコントローラー
class Management::NumericalManagementsController < ApplicationController
  include NumericSanitizer

  before_action :authenticate_user!

  def index
    year = params[:year].to_i
    month = params[:month].to_i
    year = Date.current.year if year.zero? || year < 2000 || year > 2100
    month = Date.current.month if month.zero? || month < 1 || month > 12
    @selected_date = Date.new(year, month, 1)

    @monthly_budget = Management::MonthlyBudget.find_or_initialize_by(
      budget_month: @selected_date.beginning_of_month
    )
    @monthly_budget.user_id ||= current_user.id  # 新規作成時のみ user_id を設定

    calendar_data = CalendarDataBuilderService.new(year, month).build
    @daily_data = calendar_data[:daily_data]
    @daily_targets = calendar_data[:daily_targets]

    @forecast_data = NumericalForecastService.new(
      year: year,
      month: month
    ).calculate

    # 全ての計画を取得(カテゴリー選択用、計画フィルタはJS側)
    @plans_by_category = Resources::Plan
                          .includes(:category, plan_products: :product)
                          .group_by { |plan| plan.category.name }
  end

  def calendar
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month

    calendar_data = CalendarDataBuilderService.new(@year, @month).build
    @daily_data = calendar_data[:daily_data]
    @monthly_budget = calendar_data[:monthly_budget]
    @daily_targets = calendar_data[:daily_targets]

    @forecast = NumericalForecastService.call(@year, @month)
  end

  def update_daily_target
    # デバッグログ追加
    Rails.logger.debug "===== DEBUG: update_daily_target ====="
    Rails.logger.debug "params: #{params.inspect}"
    Rails.logger.debug "management_daily_target: #{params[:management_daily_target].inspect}"
    Rails.logger.debug "daily_target: #{params[:daily_target].inspect}"

    key = params.key?(:management_daily_target) ? :management_daily_target : :daily_target

    Rails.logger.debug "key: #{key}"
    Rails.logger.debug "params[key]: #{params[key].inspect}"

    date_param = params[key][:target_date] || params[key][:date]
    target_param = params[key][:target_amount] || params[key][:target]

    Rails.logger.debug "date_param: #{date_param}"
    Rails.logger.debug "target_param: #{target_param}"
    # デバッグログここまで

    date = Date.parse(date_param)

    monthly_budget = Management::MonthlyBudget.find_or_initialize_by(
      budget_month: date.beginning_of_month
    )
    monthly_budget.user_id ||= current_user.id  # 新規作成時のみ user_id を設定
    monthly_budget.target_amount ||= 0
    monthly_budget.save! if monthly_budget.new_record?

    daily_target = Management::DailyTarget.find_or_initialize_by(
      monthly_budget: monthly_budget,
      target_date: date
    )
    daily_target.user_id ||= current_user.id  # 新規作成時のみ user_id を設定

    sanitized_value = sanitize_numeric_params(
      { target_amount: target_param },
      with_comma: [ :target_amount ]
    )[:target_amount]

    # 予算超過チェック
    if monthly_budget.target_amount > 0
      current_total = monthly_budget.daily_targets
                                    .where.not(id: daily_target.id)
                                    .sum(:target_amount)

      new_total = current_total + sanitized_value.to_i

      if new_total > monthly_budget.target_amount
        redirect_to management_numerical_managements_path(year: date.year, month: date.month),
                    alert: t("numerical_managements.messages.budget_exceeded",
                            budget: "¥#{ActiveSupport::NumberHelper.number_to_delimited(monthly_budget.target_amount)}",
                            total: "¥#{ActiveSupport::NumberHelper.number_to_delimited(new_total)}"),
                    turbo: false
        return
      end
    end

    if daily_target.update(target_amount: sanitized_value)
      redirect_to management_numerical_managements_path(year: date.year, month: date.month),
                  notice: t("numerical_managements.messages.daily_target_updated"),
                  turbo: false
    else
      redirect_to management_numerical_managements_path(year: date.year, month: date.month),
            alert: t("numerical_managements.messages.daily_target_update_failed", errors: daily_target.errors.full_messages.join(", ")),
            turbo: false
    end
  rescue Date::Error
    redirect_to management_numerical_managements_path(
      year: Date.current.year,
      month: Date.current.month
    ),
            alert: t("api.errors.invalid_date"),
            turbo: false
  end

  def bulk_update
    year = params[:year].to_i
    month = params[:month].to_i

    if params[:daily_data].present?
      converted_params = convert_daily_data_to_bulk_params(params[:daily_data])
      params.merge!(converted_params)
    end

    sanitized_params = sanitized_bulk_update_params

    # 予算超過チェック(一括更新前)
    budget_check_result = check_budget_before_bulk_update(year, month, sanitized_params)
    if budget_check_result[:exceeded]
      redirect_to management_numerical_managements_path(year: year, month: month),
                  alert: budget_check_result[:message],
                  turbo: false
      return
    end

    # ← current_userを渡す
    service = NumericalDataBulkUpdateService.new(current_user, sanitized_params)

    if service.call
      redirect_to management_numerical_managements_path(year: year, month: month),
                  notice: t("numerical_managements.messages.daily_details_updated"),
                  turbo: false
    else
      redirect_to management_numerical_managements_path(year: year, month: month),
                  alert: service.errors.join(", "),
                  turbo: false
    end
  end

  private

  def convert_daily_data_to_bulk_params(daily_data)
    monthly_budgets = {}
    daily_targets = {}
    plan_schedule_actuals = {}

    daily_data.each do |index, day_attrs|
      # 日別目標の処理(target_amountが0以外の場合のみ)
      target_amount = day_attrs[:target_amount].to_i
      if target_amount > 0
        if day_attrs[:target_id].present?
          # 既存の日別目標を更新
          daily_targets[day_attrs[:target_id]] = {
            target_amount: day_attrs[:target_amount],
            target_date: day_attrs[:date]
          }
        else
          # 新規作成の場合は日付をキーにする
          daily_targets[day_attrs[:date]] = {
            target_amount: day_attrs[:target_amount],
            target_date: day_attrs[:date]
          }
        end
      end

      # 実績の処理
      if day_attrs[:plan_schedule_id].present? && day_attrs[:actual_revenue].present?
        plan_schedule_actuals[day_attrs[:plan_schedule_id]] = {
          actual_revenue: day_attrs[:actual_revenue]
        }
      end
    end

    {
      monthly_budgets: monthly_budgets,
      daily_targets: daily_targets,
      plan_schedule_actuals: plan_schedule_actuals
    }
  end

  def bulk_update_params
    params.permit(
      :year,
      :month,
      monthly_budgets: {},
      daily_targets: {},
      plan_schedule_actuals: {},
      daily_data: {}
    )
  end

  def sanitized_bulk_update_params
    params_hash = bulk_update_params.to_h

    if params_hash[:monthly_budgets].present?
      params_hash[:monthly_budgets].each do |_, budget_attrs|
        sanitize_numeric_params(
          budget_attrs,
          with_comma: [ :target_amount ]
        )
      end
    end

    if params_hash[:daily_targets].present?
      params_hash[:daily_targets].each do |_, target_attrs|
        sanitize_numeric_params(
          target_attrs,
          with_comma: [ :target_amount ]
        )
      end
    end

    if params_hash[:plan_schedule_actuals].present?
      params_hash[:plan_schedule_actuals].each do |_, actual_attrs|
        sanitize_numeric_params(
          actual_attrs,
          with_comma: [ :actual_revenue ]
        )
      end
    end

    params_hash
  end

  # 一括更新前の予算超過チェック
  def check_budget_before_bulk_update(year, month, params_hash)
    selected_date = Date.new(year, month, 1)
    monthly_budget = Management::MonthlyBudget.find_by(
      budget_month: selected_date.beginning_of_month
    )

    # 月間予算が設定されていない場合はチェックしない
    return { exceeded: false } unless monthly_budget&.target_amount&.positive? && monthly_budget.budget_month.present?

    # 日別予算の合計を計算
    daily_targets_hash = params_hash[:daily_targets] || {}
    total_daily_target = 0

    daily_targets_hash.each do |key, target_attrs|
      target_amount = target_attrs[:target_amount].to_s.gsub(",", "").to_i
      total_daily_target += target_amount if target_amount > 0
    end

    # 予算を超えているかチェック
    if total_daily_target > monthly_budget.target_amount
      {
        exceeded: true,
        message: t("numerical_managements.messages.budget_exceeded",
                  budget: "¥#{ActiveSupport::NumberHelper.number_to_delimited(monthly_budget.target_amount)}",
                  total: "¥#{ActiveSupport::NumberHelper.number_to_delimited(total_daily_target)}")
      }
    else
      { exceeded: false }
    end
  end
end
