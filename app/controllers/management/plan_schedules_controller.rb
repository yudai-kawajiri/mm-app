# frozen_string_literal: true

#
# Management::PlanSchedulesController
#
# 計画スケジュールのCRUD操作と実績入力を管理
#
# 機能:
#   - 計画のスケジュール登録（1日1計画）
#   - 計画の変更（上書き）
#   - 実績売上の入力
#   - 計画高の自動計算
#
class Management::PlanSchedulesController < AuthenticatedController
  include NumericSanitizer

  #
  # 計画スケジュールを作成
  #
  # 1日1計画のみ（同じ日の計画は上書き）
  # 計画高は計画から自動計算
  #
  # @return [void]
  #
  def create
    permitted = sanitized_plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    unless permitted[:plan_id].present?
      redirect_to management_numerical_managements_path,
                  alert: I18n.t('api.errors.missing_required_info')
      return
    end

    plan = current_user.plans.find(permitted[:plan_id])

    @plan_schedule = Planning::PlanSchedule.find_or_initialize_by(
      user: current_user,
      scheduled_date: scheduled_date
    )

    @plan_schedule.assign_attributes(
      plan: plan,
      planned_revenue: plan.expected_revenue,
      status: @plan_schedule.persisted? ? @plan_schedule.status : :scheduled
    )

    if @plan_schedule.save
      action = @plan_schedule.previously_new_record? ? I18n.t('plan_schedules.messages.assigned', date: scheduled_date.strftime('%-m月%-d日')) : I18n.t('plan_schedules.messages.updated', date: scheduled_date.strftime('%-m月%-d日'))

      redirect_to management_numerical_managements_path(
        month: scheduled_date.strftime("%Y-%m")
      ), notice: action
    else
      redirect_to management_numerical_managements_path,
                  alert: I18n.t('plan_schedules.messages.plan_schedule_save_failed',
                                errors: @plan_schedule.errors.full_messages.join(', '))
    end
  end

  #
  # 計画スケジュールを更新
  #
  # @return [void]
  #
  def update
    permitted = sanitized_plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    @plan_schedule = current_user.plan_schedules.find(params[:id])
    plan = current_user.plans.find(permitted[:plan_id])

    @plan_schedule.assign_attributes(
      plan: plan,
      planned_revenue: plan.expected_revenue
    )

    if @plan_schedule.save
      redirect_to management_numerical_managements_path(
        month: scheduled_date.strftime("%Y-%m")
      ), notice: I18n.t('plan_schedules.messages.updated', date: scheduled_date.strftime('%-m月%-d日'))
    else
      redirect_to management_numerical_managements_path,
                  alert: I18n.t('plan_schedules.messages.plan_schedule_update_failed',
                                errors: @plan_schedule.errors.full_messages.join(', '))
    end
  end

  #
  # 実績入力専用アクション
  #
  # RESTful命名規則に準拠
  #
  # @return [void]
  #
  def actual_revenue
    @plan_schedule = current_user.plan_schedules.find(params[:id])
    permitted = sanitized_plan_schedule_params

    if @plan_schedule.update(permitted.slice(:actual_revenue))
      redirect_to management_numerical_managements_path(
        month: @plan_schedule.scheduled_date.strftime("%Y-%m")
      ), notice: t("numerical_managements.messages.actual_revenue_updated")
    else
      redirect_to management_numerical_managements_path(
        month: @plan_schedule.scheduled_date.strftime("%Y-%m")
      ), alert: t("numerical_managements.messages.actual_revenue_update_failed")
    end
  end

  private

  #
  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  #
  def plan_schedule_params
    # planning_plan_schedule でも plan_schedule でも受け付ける
    key = params.key?(:planning_plan_schedule) ? :planning_plan_schedule : :plan_schedule
    params.require(key).permit(:scheduled_date, :plan_id, :planned_revenue, :actual_revenue, :note)
  end

  #
  # サニタイズ済みパラメータ
  #
  # NumericSanitizerで全角→半角、カンマ削除、スペース削除
  #
  # @return [ActionController::Parameters]
  #
  def sanitized_plan_schedule_params
    sanitize_numeric_params(
      plan_schedule_params,
      with_comma: [:planned_revenue, :actual_revenue]
    )
  end

  #
  # 日付パース
  #
  # @param date_string [String] 日付文字列
  # @return [Date, nil] パース結果
  #
  def parse_scheduled_date(date_string)
    return nil unless date_string.present?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    redirect_to management_numerical_managements_path,
                alert: I18n.t('api.errors.invalid_date')
    nil
  end
end
