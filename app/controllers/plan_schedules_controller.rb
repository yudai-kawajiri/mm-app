# app/controllers/plan_schedules_controller.rb
class PlanSchedulesController < ApplicationController
  before_action :authenticate_user!

  def create
    @plan_schedule = current_user.plan_schedules.build(plan_schedule_params)

    if @plan_schedule.save
      redirect_to calendar_numerical_managements_path(month: @plan_schedule.scheduled_date.strftime('%Y-%m')),
                  notice: '実績を登録しました'
    else
      redirect_to calendar_numerical_managements_path(month: params[:month]),
                  alert: '実績の登録に失敗しました'
    end
  end

  def update
    @plan_schedule = current_user.plan_schedules.find(params[:id])

    if @plan_schedule.update(plan_schedule_params)
      redirect_to calendar_numerical_managements_path(month: @plan_schedule.scheduled_date.strftime('%Y-%m')),
                  notice: '実績を更新しました'
    else
      redirect_to calendar_numerical_managements_path(month: params[:month]),
                  alert: '実績の更新に失敗しました'
    end
  end

  private

  def plan_schedules_params
    params.require(:plan_schedule).permit(:scheduled_date, :plan_id, :planned_revenue, :actual_revenue)
  end
end
