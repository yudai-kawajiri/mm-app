# frozen_string_literal: true

# 数値管理機能のコントローラー
class Management::NumericalManagementsController < ApplicationController
  layout "authenticated_layout"
  include NumericSanitizer
  before_action :authenticate_user!

  def index
    year = params[:year].to_i
    month = params[:month].to_i
    year = Date.current.year if year.zero? || year < 2000 || year > 2100
    month = Date.current.month if month.zero? || month < 1 || month > 12
    @selected_date = Date.new(year, month, 1)

    @monthly_budget = current_user.monthly_budgets.find_or_create_by(
      budget_month: @selected_date.beginning_of_month
    ) do |budget|
      budget.target_amount ||= 0
    end

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

    render partial: "calendar", locals: { daily_data: @daily_data }
  end

  def update_daily_target
    year = params[:year].to_i
    month = params[:month].to_i
    date = params[:date].to_i

    target_date = Date.new(year, month, date)
    monthly_budget = current_user.monthly_budgets.find_or_create_by(
      budget_month: target_date.beginning_of_month
    )

    daily_target = monthly_budget.daily_targets.find_or_initialize_by(target_date: target_date)
    daily_target.target_amount = sanitize_without_comma(params[:management_daily_target][:target_amount])
    daily_target.user_id = current_user.id

    if daily_target.save
      logger.error("DailyTarget save failed: #{daily_target.errors.full_messages.join(", ")}")
      render json: { success: true, target_amount: daily_target.target_amount }
    else
      render json: { success: false, errors: daily_target.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def bulk_update
    monthly_budget = current_user.monthly_budgets.find_or_create_by(
      budget_month: params[:budget_month]
    )

    ActiveRecord::Base.transaction do
      if params[:monthly_target].present?
        monthly_budget.update!(target_amount: sanitize_numeric(params[:monthly_target]))
      end

      if params[:daily_targets].present?
        params[:daily_targets].each do |date_str, amount|
          target_date = Date.parse(date_str)
          daily_target = monthly_budget.daily_targets.find_or_initialize_by(target_date: target_date)
          daily_target.target_amount = sanitize_numeric(amount)
          daily_target.save!
        end
      end
    end

    redirect_to management_numerical_managements_path(
      year: monthly_budget.year,
      month: monthly_budget.month
    ), notice: t("numerical_managements.messages.bulk_update_success")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to management_numerical_managements_path, alert: e.message
  end
end
