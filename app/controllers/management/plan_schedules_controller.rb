# frozen_string_literal: true

class Management::PlanSchedulesController < Management::BaseController
  include NumericSanitizer

  # PATCH /bulk_update 用のアクションとして、既存のcreateロジックをベースに統合
  def bulk_update
    permitted = sanitized_plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    unless permitted[:plan_id].present?
      redirect_to management_numerical_managements_path(
        year: scheduled_date.year,
        month: scheduled_date.month
      ), alert: I18n.t("api.errors.missing_required_info")
      return
    end

    plan = Resources::Plan.find(permitted[:plan_id])

    # find_or_initialize_by を使うことで、新規でも更新でも対応可能にする
    @plan_schedule = Planning::PlanSchedule.find_or_initialize_by(
      scheduled_date: scheduled_date,
      store_id: current_store&.id
    )

    is_new_record = @plan_schedule.new_record?
    @plan_schedule.user_id ||= current_user.id
    @plan_schedule.company_id ||= current_company.id

    @plan_schedule.assign_attributes(
      plan: plan,
      status: @plan_schedule.persisted? ? @plan_schedule.status : :scheduled
    )

    if @plan_schedule.save
      # productsパラメータの有無でスナップショット作成を分岐
      if params[:plan_schedule][:products].present?
        create_snapshot_from_products(params[:plan_schedule][:products])
      else
        @plan_schedule.create_snapshot_from_plan
      end

      # ja.ymlのパスに合わせてメッセージを選択
      msg_key = is_new_record ? "plan_assigned" : "plan_updated"
      notice_message = I18n.t("flash_messages.plan_schedules.messages.#{msg_key}")

      redirect_to management_numerical_managements_path(
        year: scheduled_date.year,
        month: scheduled_date.month
      ), notice: notice_message
    else
      err_key = is_new_record ? "plan_schedule_save_failed" : "plan_schedule_update_failed"
      redirect_to management_numerical_managements_path(
        year: scheduled_date.year,
        month: scheduled_date.month
      ), alert: I18n.t("flash_messages.plan_schedules.messages.#{err_key}", errors: @plan_schedule.errors.full_messages.join(", "))
    end
  end

  # フォームがPOST(create)で来てもPATCH(bulk_update)と同じ挙動にする
  def create
    bulk_update
  end

  # ID指定の更新も壊さないように残す
  def update
    @plan_schedule = Planning::PlanSchedule.find(params[:id])
    bulk_update
  end

  def actual_revenue
    @plan_schedule = Planning::PlanSchedule.find(params[:id])
    permitted = sanitized_plan_schedule_params

    if @plan_schedule.update(permitted.slice(:actual_revenue))
      @plan_schedule.create_snapshot_from_plan unless @plan_schedule.has_snapshot?

      redirect_to management_numerical_managements_path(
        year: @plan_schedule.scheduled_date.year,
        month: @plan_schedule.scheduled_date.month
      ), notice: t("flash_messages.numerical_managements.messages.actual_revenue_updated")
    else
      redirect_to management_numerical_managements_path(
        year: @plan_schedule.scheduled_date.year,
        month: @plan_schedule.scheduled_date.month
      ), alert: t("flash_messages.numerical_managements.messages.actual_revenue_update_failed")
    end
  end

  private

  def plan_schedule_params
    key = params.key?(:planning_plan_schedule) ? :planning_plan_schedule : :plan_schedule
    params.require(key).permit(:scheduled_date, :plan_id, :actual_revenue, :description, products: {})
  end

  def sanitized_plan_schedule_params
    sanitize_numeric_params(
      plan_schedule_params,
      with_comma: [ :actual_revenue ]
    )
  end

  def parse_scheduled_date(date_string)
    return nil unless date_string.present?
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    redirect_to management_numerical_managements_path(
      year: Date.current.year,
      month: Date.current.month
    ), alert: I18n.t("api.errors.invalid_date")
    nil
  end

  def create_snapshot_from_products(products_params)
    # to_h ではなく to_unsafe_h を使用して、ネストされたパラメータを許可します
    products_data = products_params.to_unsafe_h.map do |product_id, production_count|
      { product_id: product_id, production_count: production_count.to_i }
    end

    @plan_schedule.update_products_snapshot(products_data)
  end
end
