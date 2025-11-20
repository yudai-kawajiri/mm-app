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

    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: @selected_date.beginning_of_month
    )

    calendar_data = CalendarDataBuilderService.new(current_user, year, month).build
    @daily_data = calendar_data[:daily_data]
    @daily_targets = calendar_data[:daily_targets]

    @forecast_data = NumericalForecastService.new(
      user: current_user,
      year: year,
      month: month
    ).calculate

    @plans_by_category = current_user.plans
                                      .includes(:category, plan_products: :product)
                                      .group_by { |plan| plan.category.name }
  end

  def calendar
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month

    calendar_data = CalendarDataBuilderService.new(current_user, @year, @month).build
    @daily_data = calendar_data[:daily_data]
    @monthly_budget = calendar_data[:monthly_budget]
    @daily_targets = calendar_data[:daily_targets]

    @forecast = NumericalForecastService.call(current_user, @year, @month)
  end

  def update_daily_target
    key = params.key?(:management_daily_target) ? :management_daily_target : :daily_target
    date_param = params[key][:target_date] || params[key][:date]
    target_param = params[key][:target_amount] || params[key][:target]

    date = Date.parse(date_param)

    monthly_budget = current_user.monthly_budgets.find_or_create_by!(
      budget_month: date.beginning_of_month
    ) do |budget|
      budget.target_amount = 0
    end

    daily_target = Management::DailyTarget.find_or_initialize_by(
      user: current_user,
      monthly_budget: monthly_budget,
      target_date: date
    )

    sanitized_value = sanitize_numeric_params(
      { target_amount: target_param },
      with_comma: [:target_amount]
    )[:target_amount]

    # 予算超過チェック
    if monthly_budget.target_amount > 0
      # 現在の日別予算の合計を計算（更新対象を除く）
      current_total = monthly_budget.daily_targets
                                    .where.not(id: daily_target.id)
                                    .sum(:target_amount)

      new_total = current_total + sanitized_value.to_i

      if new_total > monthly_budget.target_amount
        redirect_to management_numerical_managements_path(year: date.year, month: date.month),
                    alert: t('numerical_managements.messages.budget_exceeded',
                            budget: number_to_currency(monthly_budget.target_amount, unit: '¥', precision: 0),
                            total: number_to_currency(new_total, unit: '¥', precision: 0)),
                    turbo: false
        return
      end
    end

    if daily_target.update(target_amount: sanitized_value)
      redirect_to management_numerical_managements_path(year: date.year, month: date.month),
                  notice: t('numerical_managements.messages.daily_target_updated'),
                  turbo: false
    else
      redirect_to management_numerical_managements_path(year: date.year, month: date.month),
            alert: t('numerical_managements.messages.daily_target_update_failed', errors: daily_target.errors.full_messages.join(', ')),
            turbo: false
    end
  rescue Date::Error
    redirect_to management_numerical_managements_path(
      year: Date.current.year,
      month: Date.current.month
    ),
            alert: t('api.errors.invalid_date'),
            turbo: false
  end

  def bulk_update
    year = params[:year].to_i
    month = params[:month].to_i

    if params[:daily_data].present?
      converted_params = convert_daily_data_to_bulk_params(params[:daily_data])
      params.merge!(converted_params)
    end

    # 予算超過チェック（一括更新前）
    budget_check_result = check_budget_before_bulk_update(year, month, sanitized_bulk_update_params)
    if budget_check_result[:exceeded]
      redirect_to management_numerical_managements_path(year: year, month: month),
                  alert: budget_check_result[:message],
                  turbo: false
      return
    end

    service = NumericalDataBulkUpdateService.new(current_user, sanitized_bulk_update_params)

    if service.call
      redirect_to management_numerical_managements_path(year: year, month: month),
                  notice: t('numerical_managements.messages.daily_details_updated'),
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
        # 日別目標の処理（target_amountが0以外の場合のみ）
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
          with_comma: [:target_amount]
        )
      end
    end

    if params_hash[:daily_targets].present?
      params_hash[:daily_targets].each do |_, target_attrs|
        sanitize_numeric_params(
          target_attrs,
          with_comma: [:target_amount]
        )
      end
    end

    if params_hash[:plan_schedule_actuals].present?
      params_hash[:plan_schedule_actuals].each do |_, actual_attrs|
        sanitize_numeric_params(
          actual_attrs,
          with_comma: [:actual_revenue]
        )
      end
    end

    params_hash
  end

  # 一括更新前の予算超過チェック
  def check_budget_before_bulk_update(year, month, params_hash)
    selected_date = Date.new(year, month, 1)
    monthly_budget = current_user.monthly_budgets.find_by(
      budget_month: selected_date.beginning_of_month
    )

    # 月間予算が設定されていない場合はチェックしない
    return { exceeded: false } unless monthly_budget&.target_amount&.positive?

    # 日別予算の合計を計算
    daily_targets_hash = params_hash[:daily_targets] || {}
    total_daily_target = 0

    daily_targets_hash.each do |key, target_attrs|
      target_amount = target_attrs[:target_amount].to_s.gsub(',', '').to_i
      total_daily_target += target_amount if target_amount > 0
    end

    # 予算を超えているかチェック
    if total_daily_target > monthly_budget.target_amount
      {
        exceeded: true,
        message: t('numerical_managements.messages.budget_exceeded',
                  budget: number_to_currency(monthly_budget.target_amount, unit: '¥', precision: 0),
                  total: number_to_currency(total_daily_target, unit: '¥', precision: 0))
      }
    else
      { exceeded: false }
    end
  end
end
