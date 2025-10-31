# app/controllers/numerical_managements_controller.rb
class NumericalManagementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_year_month, only: [:index, :calendar]

  def index
    # ✅ budget_month を使って検索
    budget_month = Date.new(@year, @month, 1)
    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: budget_month
    )

    @daily_targets = current_user.daily_targets
                                 .where(year: @year, month: @month)
                                 .index_by { |dt| dt.day }

    @daily_actuals = current_user.daily_actuals
                                 .where(year: @year, month: @month)
                                 .index_by { |da| da.day }

    @days_in_month = Date.new(@year, @month, -1).day

    @forecast_service = NumericalForecastService.new(
      @monthly_budget,
      @daily_targets,
      @daily_actuals,
      @days_in_month
    )
  end

  def calendar
    @calendar_service = CalendarDataService.new(
      current_user,
      @year,
      @month
    )

    @calendar_data = @calendar_service.build_calendar_data
    @monthly_budget = @calendar_service.monthly_budget
    @categories = current_user.categories.order(:name)
  end

  def update_daily_target
    @daily_target = current_user.daily_targets.find_or_initialize_by(
      year: params[:year],
      month: params[:month],
      day: params[:day]
    )

    if @daily_target.update(daily_target_params)
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t('numerical_managements.messages.daily_target_updated')
    else
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.daily_target_update_failed')
    end
  end

  def destroy_daily_target
    @daily_target = current_user.daily_targets.find_by(
      year: params[:year],
      month: params[:month],
      day: params[:day]
    )

    if @daily_target&.destroy
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t('numerical_managements.messages.daily_target_deleted')
    else
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.daily_target_delete_failed')
    end
  end

  def update_actual
    @daily_actual = current_user.daily_actuals.find_or_initialize_by(
      year: params[:year],
      month: params[:month],
      day: params[:day]
    )

    if @daily_actual.update(actual_params)
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t('numerical_managements.messages.actual_updated')
    else
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.actual_update_failed')
    end
  end

  def destroy_actual
    @daily_actual = current_user.daily_actuals.find_by(
      year: params[:year],
      month: params[:month],
      day: params[:day]
    )

    if @daily_actual&.destroy
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t('numerical_managements.messages.actual_deleted')
    else
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.actual_delete_failed')
    end
  end

  def assign_plan
    begin
      plan = current_user.plans.find(params[:plan_id])

      @plan_schedule = current_user.plan_schedules.new(
        plan: plan,
        year: params[:year],
        month: params[:month],
        day: params[:day]
      )

      if @plan_schedule.save
        redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                    notice: t('numerical_managements.messages.plan_assigned')
      else
        redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                    alert: t('numerical_managements.messages.plan_assign_failed')
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.plan_not_found')
    end
  end

  def unassign_plan
    @plan_schedule = current_user.plan_schedules.find(params[:id])

    if @plan_schedule.destroy
      redirect_to calendar_numerical_managements_path(
        year: @plan_schedule.year,
        month: @plan_schedule.month
      ), notice: t('numerical_managements.messages.plan_unassigned')
    else
      redirect_to calendar_numerical_managements_path(
        year: @plan_schedule.year,
        month: @plan_schedule.month
      ), alert: t('numerical_managements.messages.plan_unassign_failed')
    end
  end

  private

  def set_year_month
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month
  end

  def daily_target_params
    params.require(:daily_target).permit(:target_revenue)
  end

  def actual_params
    params.require(:daily_actual).permit(:actual_revenue)
  end
end
