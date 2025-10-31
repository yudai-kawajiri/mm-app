class NumericalManagementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_year_month, only: [:index, :calendar]

  def index
    @selected_date = Date.new(@year, @month, 1)
    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: @selected_date
    )

    start_date = @selected_date
    end_date = Date.new(@year, @month, -1)

    @daily_targets = current_user.daily_targets
                                 .where(target_date: start_date..end_date)
                                 .index_by { |dt| dt.target_date.day }

    @days_in_month = end_date.day

    @forecast_service = NumericalForecastService.new(
      current_user,
      @year,
      @month
    )

    @forecast_data = @forecast_service.calculate
    @daily_data = build_daily_data(start_date, end_date)
  end

  def calendar
    @selected_date = Date.new(@year, @month, 1)

    @calendar_service = CalendarDataService.new(
      current_user,
      @year,
      @month
    )

    @calendar_data = @calendar_service.call
    @monthly_budget = @calendar_service.budget
    @budget = @monthly_budget  # ✅ これを追加
    @categories = current_user.categories.order(:name)

    @plans_by_category = current_user.plans
                                    .includes(:category)
                                    .where(status: :active)
                                    .group_by { |plan| plan.category.name }
  end


  def update_daily_target
    target_date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    @daily_target = current_user.daily_targets.find_or_initialize_by(
      target_date: target_date
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
    target_date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    @daily_target = current_user.daily_targets.find_by(
      target_date: target_date
    )

    if @daily_target&.destroy
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t('numerical_managements.messages.daily_target_deleted')
    else
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.daily_target_delete_failed')
    end
  end

  def assign_plan
    begin
      plan = current_user.plans.find(params[:plan_id])

      # scheduled_date を構築
      scheduled_date = Date.new(
        params[:year].to_i,
        params[:month].to_i,
        params[:day].to_i
      )

      @plan_schedule = current_user.plan_schedules.new(
        plan: plan,
        scheduled_date: scheduled_date,
        planned_revenue: plan.expected_revenue  # これを追加
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
    if params[:month]&.include?('-')
      date_parts = params[:month].split('-')
      @year = date_parts[0].to_i
      @month = date_parts[1].to_i
    else
      @year = params[:year]&.to_i || Date.current.year
      @month = params[:month]&.to_i || Date.current.month
    end
  end

  def build_daily_data(start_date, end_date)
    (start_date..end_date).map do |date|
      day = date.day
      daily_target = @daily_targets[day]

      plan_schedules = current_user.plan_schedules
                                   .where(scheduled_date: date)
                                   .includes(plan: { plan_products: :product })

      planned_revenue = plan_schedules.sum do |ps|
        ps.plan.plan_products.sum { |pp| pp.product.price * pp.production_count }
      end

      actual_revenue = plan_schedules.where.not(actual_revenue: nil).sum(:actual_revenue)

      {
        date: date,
        target: daily_target&.target_amount || 0,
        planned: planned_revenue,
        actual: actual_revenue,
        plan_schedules: plan_schedules
      }
    end
  end

  def daily_target_params
    params.require(:daily_target).permit(:target_amount, :note)
  end
end
