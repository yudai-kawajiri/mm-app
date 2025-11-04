# app/controllers/plan_schedules_controller.rb
class PlanSchedulesController < AuthenticatedController
  def create
    # Strong Parameters で受け取る
    permitted = plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    # パラメータチェック
    unless permitted[:plan_id].present?
      redirect_to numerical_managements_path,
                  alert: I18n.t('api.errors.missing_required_info')
      return
    end

    # 1日1計画のみ（同じ日の計画は上書き）
    @plan_schedule = PlanSchedule.find_or_initialize_by(
      user: current_user,
      scheduled_date: scheduled_date
    )

    # Strong Parameters で受け取った値を設定
    @plan_schedule.assign_attributes(
      permitted.except(:scheduled_date).merge(
        status: @plan_schedule.persisted? ? @plan_schedule.status : :scheduled
      )
    )

    Rails.logger.info "=== Creating/Updating PlanSchedule ==="
    Rails.logger.info "User ID: #{current_user.id}"
    Rails.logger.info "Scheduled Date: #{scheduled_date}"
    Rails.logger.info "Plan ID: #{permitted[:plan_id]}"
    Rails.logger.info "Planned Revenue: #{permitted[:planned_revenue]}"
    Rails.logger.info "Is new record: #{@plan_schedule.new_record?}"

    if @plan_schedule.save
      action = @plan_schedule.previously_new_record? ? I18n.t('plan_schedules.messages.assigned') : I18n.t('plan_schedules.messages.updated')
      Rails.logger.info "=== PlanSchedule Saved Successfully ==="

      redirect_to numerical_managements_path(
        month: scheduled_date.strftime("%Y-%m")
      ), notice: I18n.t('plan_schedules.messages.plan_schedule_saved', date: scheduled_date.strftime('%-m月%-d日'), action: action)
    else
      Rails.logger.error "=== PlanSchedule Save Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      redirect_to numerical_managements_path,
                  alert: I18n.t('plan_schedules.messages.plan_schedule_save_failed', errors: @plan_schedule.errors.full_messages.join(', '))
    end
  end

  def update
    # Strong Parameters で受け取る
    permitted = plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    # 既存レコードを取得
    @plan_schedule = current_user.plan_schedules.find(params[:id])

    # Strong Parameters で受け取った値を設定
    @plan_schedule.assign_attributes(permitted.except(:scheduled_date))

    Rails.logger.info "=== Updating PlanSchedule ID: #{@plan_schedule.id} ==="
    Rails.logger.info "Plan ID: #{permitted[:plan_id]}"
    Rails.logger.info "Planned Revenue: #{permitted[:planned_revenue]}"

    if @plan_schedule.save
      Rails.logger.info "=== PlanSchedule Updated Successfully ==="

      redirect_to numerical_managements_path(
        month: scheduled_date.strftime("%Y-%m")
      ), notice: I18n.t('plan_schedules.messages.plan_schedule_updated_with_date', date: scheduled_date.strftime('%-m月%-d日'))
    else
      Rails.logger.error "=== PlanSchedule Update Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      redirect_to numerical_managements_path,
                  alert: I18n.t('plan_schedules.messages.plan_schedule_update_failed', errors: @plan_schedule.errors.full_messages.join(', '))
    end
  end

  # 実績入力専用アクション
  def actual_revenue
    @plan_schedule = current_user.plan_schedules.find(params[:id])

    Rails.logger.info "=== Updating Actual Revenue for PlanSchedule ID: #{@plan_schedule.id} ==="
    Rails.logger.info "Actual Revenue: #{plan_schedule_params[:actual_revenue]}"

    # Strong Parameters を使用
    if @plan_schedule.update(plan_schedule_params.slice(:actual_revenue))
      Rails.logger.info "=== Actual Revenue Updated Successfully ==="

      redirect_to numerical_managements_path(
        month: @plan_schedule.scheduled_date.strftime("%Y-%m")
      ), notice: t("numerical_managements.messages.actual_revenue_updated")
    else
      Rails.logger.error "=== Actual Revenue Update Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      redirect_to numerical_managements_path(
        month: @plan_schedule.scheduled_date.strftime("%Y-%m")
      ), alert: t("numerical_managements.messages.actual_revenue_update_failed")
    end
  end


  private

  # Strong Parameters
  def plan_schedule_params
    params.require(:plan_schedule).permit(:scheduled_date, :plan_id, :planned_revenue, :actual_revenue, :note)
  end

  # 日付パース（共通化）
  def parse_scheduled_date(date_string)
    return nil unless date_string.present?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    redirect_to numerical_managements_path,
                alert: I18n.t('api.errors.invalid_date')
    nil
  end
end