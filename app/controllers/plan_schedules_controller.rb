class PlanSchedulesController < ApplicationController
  before_action :authenticate_user!

  def create
    @plan_schedule = PlanSchedule.new(plan_schedule_params)
    @plan_schedule.user_id = current_user.id
    @plan_schedule.status = :scheduled

    Rails.logger.info "=== Creating PlanSchedule ==="
    Rails.logger.info "Params: #{plan_schedule_params.inspect}"
    Rails.logger.info "User ID: #{current_user.id}"
    Rails.logger.info "Scheduled Date: #{@plan_schedule.scheduled_date.inspect}"

    if @plan_schedule.save
      Rails.logger.info "=== PlanSchedule Saved Successfully ==="
      # dateパラメータに変更（monthではなく）
      redirect_to calendar_numerical_managements_path(date: @plan_schedule.scheduled_date),
                  notice: '計画を登録しました'
    else
      Rails.logger.error "=== PlanSchedule Save Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      # scheduled_dateがnilの場合のフォールバック
      fallback_date = params[:plan_schedule][:scheduled_date].present? ?
                      params[:plan_schedule][:scheduled_date].to_date :
                      Date.current

      redirect_to calendar_numerical_managements_path(date: fallback_date),
                  alert: "計画の登録に失敗しました: #{@plan_schedule.errors.full_messages.join(', ')}"
    end
  end

  def update
    @plan_schedule = PlanSchedule.find(params[:id])

    if @plan_schedule.update(plan_schedule_params)
      # dateパラメータに変更（monthではなく）
      redirect_to calendar_numerical_managements_path(date: @plan_schedule.scheduled_date),
                  notice: '実績を更新しました'
    else
      fallback_date = params[:plan_schedule][:scheduled_date].present? ?
                      params[:plan_schedule][:scheduled_date].to_date :
                      Date.current

      redirect_to calendar_numerical_managements_path(date: fallback_date),
                  alert: "実績の更新に失敗しました: #{@plan_schedule.errors.full_messages.join(', ')}"
    end
  end

  private

  def plan_schedule_params
    params.require(:plan_schedule).permit(:scheduled_date, :plan_id, :planned_revenue, :actual_revenue, :note)
  end
end
