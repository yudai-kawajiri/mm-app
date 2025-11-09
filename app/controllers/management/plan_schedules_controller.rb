# frozen_string_literal: true

# PlanSchedulesController
#
# 計画スケジュールのCRUD操作と実績入力を管理
#
# 機能:
#   - 計画のスケジュール登録（1日1計画）
#   - 計画の変更（上書き）
#   - 実績売上の入力
#   - 計画高の自動計算
class PlanSchedulesController < AuthenticatedController
  # 計画スケジュールを作成
  #
  # 1日1計画のみ（同じ日の計画は上書き）
  # 計画高は計画から自動計算
  #
  # @return [void]
  def create
    permitted = plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    unless permitted[:plan_id].present?
      redirect_to numerical_managements_path,
                  alert: I18n.t('api.errors.missing_required_info')
      return
    end

    # 計画を取得
    plan = current_user.plans.find(permitted[:plan_id])

    # 1日1計画（find_or_initialize_by）
    @plan_schedule = PlanSchedule.find_or_initialize_by(
      user: current_user,
      scheduled_date: scheduled_date
    )

    # 計画高は計画から自動計算
    @plan_schedule.assign_attributes(
      plan: plan,
      planned_revenue: plan.expected_revenue,
      status: @plan_schedule.persisted? ? @plan_schedule.status : :scheduled
    )

    Rails.logger.info "=== Creating/Updating PlanSchedule ==="
    Rails.logger.info "User ID: #{current_user.id}"
    Rails.logger.info "Scheduled Date: #{scheduled_date}"
    Rails.logger.info "Plan ID: #{plan.id}"
    Rails.logger.info "Planned Revenue (auto-calculated): #{plan.expected_revenue}"

    if @plan_schedule.save
      action = @plan_schedule.previously_new_record? ? I18n.t('plan_schedules.messages.assigned') : I18n.t('plan_schedules.messages.updated')
      Rails.logger.info "=== PlanSchedule Saved Successfully ==="

      redirect_to numerical_managements_path(
        month: scheduled_date.strftime("%Y-%m")
      ), notice: I18n.t('plan_schedules.messages.plan_schedule_saved',
                        date: scheduled_date.strftime('%-m月%-d日'),
                        action: action)
    else
      Rails.logger.error "=== PlanSchedule Save Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      redirect_to numerical_managements_path,
                  alert: I18n.t('plan_schedules.messages.plan_schedule_save_failed',
                                errors: @plan_schedule.errors.full_messages.join(', '))
    end
  end

  # 計画スケジュールを更新
  #
  # @return [void]
  def update
    permitted = plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    @plan_schedule = current_user.plan_schedules.find(params[:id])

    # 計画を取得
    plan = current_user.plans.find(permitted[:plan_id])

    # 計画高は計画から自動計算
    @plan_schedule.assign_attributes(
      plan: plan,
      planned_revenue: plan.expected_revenue
    )

    Rails.logger.info "=== Updating PlanSchedule ID: #{@plan_schedule.id} ==="
    Rails.logger.info "Plan ID: #{plan.id}"
    Rails.logger.info "Planned Revenue (auto-calculated): #{plan.expected_revenue}"

    if @plan_schedule.save
      Rails.logger.info "=== PlanSchedule Updated Successfully ==="

      redirect_to numerical_managements_path(
        month: scheduled_date.strftime("%Y-%m")
      ), notice: I18n.t('plan_schedules.messages.plan_schedule_updated_with_date',
                        date: scheduled_date.strftime('%-m月%-d日'))
    else
      Rails.logger.error "=== PlanSchedule Update Failed ==="
      Rails.logger.error "Errors: #{@plan_schedule.errors.full_messages.join(', ')}"

      redirect_to numerical_managements_path,
                  alert: I18n.t('plan_schedules.messages.plan_schedule_update_failed',
                                errors: @plan_schedule.errors.full_messages.join(', '))
    end
  end

  # 実績入力専用アクション
  #
  # RESTful命名規則に準拠
  #
  # @return [void]
  def update_actual_revenue
    @plan_schedule = current_user.plan_schedules.find(params[:id])

    Rails.logger.info "=== Updating Actual Revenue for PlanSchedule ID: #{@plan_schedule.id} ==="
    Rails.logger.info "Actual Revenue: #{plan_schedule_params[:actual_revenue]}"

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
  #
  # @return [ActionController::Parameters]
  def plan_schedule_params
    params.require(:plan_schedule).permit(:scheduled_date, :plan_id, :planned_revenue, :actual_revenue, :note)
  end

  # 日付パース
  #
  # @param date_string [String] 日付文字列
  # @return [Date, nil] パース結果
  def parse_scheduled_date(date_string)
    return nil unless date_string.present?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    redirect_to numerical_managements_path,
                alert: I18n.t('api.errors.invalid_date')
    nil
  end
end
