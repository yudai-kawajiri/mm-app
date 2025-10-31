class PlanSchedulesController < ApplicationController
  before_action :authenticate_user!

  def create
    scheduled_date_str = params[:plan_schedule][:scheduled_date]
    plan_id = params[:plan_schedule][:plan_id]
    planned_revenue = params[:plan_schedule][:planned_revenue]

    # パラメータチェック
    unless scheduled_date_str.present? && plan_id.present?
      redirect_to calendar_numerical_managements_path,
                  alert: '必要な情報が不足しています。'
      return
    end

    begin
      scheduled_date = Date.parse(scheduled_date_str)
    rescue ArgumentError, TypeError
      redirect_to calendar_numerical_managements_path,
                  alert: '無効な日付形式です。'
      return
    end

    # 1日1計画のみ（同じ日の計画は上書き）
    @plan_schedule = PlanSchedule.find_or_initialize_by(
      user: current_user,
      scheduled_date: scheduled_date
    )

    @plan_schedule.plan_id = plan_id
    @plan_schedule.planned_revenue = planned_revenue
    @plan_schedule.status = :scheduled unless @plan_schedule.persisted?

    Rails.logger.info "=== Creating/Updating PlanSchedule ==="
    Rails.logger.info "User ID: #{current_user.id}"
    Rails.logger.info "Scheduled Date: #{scheduled_date}"
    Rails.logger.info "Plan ID: #{plan_id}"
    Rails.logger.info "Planned Revenue: #{planned_revenue}"
    Rails.logger.info "Is new record: #{@plan_schedule.new_record?}"

    if @plan_schedule.save
      message = @plan_schedule.previously_new_record? ? '登録' : '更新'
      Rails.logger.info "=== PlanSchedule Saved Successfully ==="

      redirect_to calendar_numerical_managements_path(month: scheduled_date.strftime('%Y-%m')),
                  notice: "計画を#{message}しました"
    else
      Rails.logger.error "=== PlanSchedule Save Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      redirect_to calendar_numerical_managements_path(month: scheduled_date.strftime('%Y-%m')),
                  alert: "計画の#{@plan_schedule.new_record? ? '登録' : '更新'}に失敗しました: #{@plan_schedule.errors.full_messages.join(', ')}"
    end
  end


  def update
    @plan_schedule = PlanSchedule.find(params[:id])

    # 権限チェック
    unless @plan_schedule.user_id == current_user.id
      redirect_to calendar_numerical_managements_path,
                  alert: '権限がありません。'
      return
    end

    Rails.logger.info "=== Updating PlanSchedule ID: #{@plan_schedule.id} ==="
    Rails.logger.info "Params: #{plan_schedule_params.inspect}"

    if @plan_schedule.update(plan_schedule_params)
      Rails.logger.info "=== PlanSchedule Updated Successfully ==="

      redirect_to calendar_numerical_managements_path(month: @plan_schedule.scheduled_date.strftime('%Y-%m')),
                  notice: '実績を更新しました'
    else
      Rails.logger.error "=== PlanSchedule Update Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      fallback_date = @plan_schedule.scheduled_date || Date.current

      redirect_to calendar_numerical_managements_path(month: fallback_date.strftime('%Y-%m')),
                  alert: "実績の更新に失敗しました: #{@plan_schedule.errors.full_messages.join(', ')}"
    end
  end

  # 実績入力専用アクション
  def actual_revenue
    @plan_schedule = current_user.plan_schedules.find(params[:id])

    Rails.logger.info "=== Updating Actual Revenue for PlanSchedule ID: #{@plan_schedule.id} ==="
    Rails.logger.info "Actual Revenue: #{params[:plan_schedule][:actual_revenue]}"

    if @plan_schedule.update(actual_revenue: params[:plan_schedule][:actual_revenue])
      Rails.logger.info "=== Actual Revenue Updated Successfully ==="

      redirect_to calendar_numerical_managements_path(
        month: @plan_schedule.scheduled_date.strftime('%Y-%m')
      ), notice: t('numerical_managements.messages.actual_revenue_updated')
    else
      Rails.logger.error "=== Actual Revenue Update Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      redirect_to calendar_numerical_managements_path(
        month: @plan_schedule.scheduled_date.strftime('%Y-%m')
      ), alert: t('numerical_managements.messages.actual_revenue_update_failed')
    end
  end


  private

  def plan_schedule_params
    params.require(:plan_schedule).permit(:scheduled_date, :plan_id, :planned_revenue, :actual_revenue, :note)
  end
end