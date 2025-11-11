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

    # ★★★ 修正: plan_products をプリロード ★★★
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

    if daily_target.update(target_amount: sanitized_value)
      redirect_to management_numerical_managements_path(month: date.strftime('%Y-%m')),
                  notice: t('numerical_managements.messages.daily_target_updated'),
                  turbo: false
    else
      redirect_to management_numerical_managements_path(month: date.strftime('%Y-%m')),
                  alert: "更新に失敗しました: #{daily_target.errors.full_messages.join(', ')}",
                  turbo: false
    end
  rescue Date::Error
    redirect_to management_numerical_managements_path,
                alert: '日付の形式が正しくありません',
                turbo: false
  end

  def bulk_update
    year = params[:year].to_i
    month = params[:month].to_i

    if params[:daily_data].present?
      converted_params = convert_daily_data_to_bulk_params(params[:daily_data])
      params.merge!(converted_params)
    end

    service = NumericalDataBulkUpdateService.new(current_user, sanitized_bulk_update_params)

    if service.call
      redirect_to management_numerical_managements_path(year: year, month: month),
                  notice: t('numerical_managements.messages.data_updated'),
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
      if day_attrs[:target_id].present? && day_attrs[:target_amount].present?
        daily_targets[day_attrs[:target_id]] = {
          target_amount: day_attrs[:target_amount]
        }
      end

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
      monthly_budgets: [:target_amount],
      daily_targets: [:target_amount],
      plan_schedule_actuals: [:actual_revenue]
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
end
