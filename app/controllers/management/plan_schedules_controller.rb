# frozen_string_literal: true

class Management::PlanSchedulesController < Management::BaseController
  include NumericSanitizer

  def create
    permitted = sanitized_plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    unless permitted[:plan_id].present?
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        year: scheduled_date.year,
        month: scheduled_date.month
      ),
                  alert: I18n.t("api.errors.missing_required_info")
      return
    end

    plan = Resources::Plan.find(permitted[:plan_id])

    # 修正: store_id を条件に追加して店舗スコープを適用
    @plan_schedule = Planning::PlanSchedule.find_or_initialize_by(
      scheduled_date: scheduled_date,
      store_id: current_store&.id
    )
    @plan_schedule.user_id ||= current_user.id
    @plan_schedule.company_id ||= current_company.id

    @plan_schedule.assign_attributes(
      plan: plan,
      status: @plan_schedule.persisted? ? @plan_schedule.status : :scheduled
    )

    if @plan_schedule.save
      if params[:plan_schedule][:products].present?
        @plan_schedule.create_snapshot_from_products(params[:plan_schedule][:products])
      else
        @plan_schedule.create_snapshot_from_plan
      end

      action = @plan_schedule.previously_new_record? ? I18n.t("flash_messages.numerical_managements.messages.plan_assigned") : I18n.t("flash_messages.numerical_managements.messages.plan_assigned")

      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        year: scheduled_date.year,
        month: scheduled_date.month
      ), notice: action
    else
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        year: scheduled_date.year,
        month: scheduled_date.month
      ),
                  alert: I18n.t("flash_messages.plan_schedule.create.failure")
    end
  end

  def update
    permitted = sanitized_plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    @plan_schedule = Planning::PlanSchedule.find(params[:id])
    plan = Resources::Plan.find(permitted[:plan_id])

    @plan_schedule.assign_attributes(
      plan: plan
    )

    if @plan_schedule.save
      if permitted[:products].present?
        @plan_schedule.create_snapshot_from_products(params[:plan_schedule][:products])
      else
        @plan_schedule.create_snapshot_from_plan
      end

      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        year: scheduled_date.year,
        month: scheduled_date.month
      ), notice: I18n.t("numerical_managements.messages.plan_assigned")
    else
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        year: scheduled_date.year,
        month: scheduled_date.month
      ),
                  alert: I18n.t("flash_messages.plan_schedule.update.failure")
    end
  end

  def actual_revenue
    @plan_schedule = Planning::PlanSchedule.find(params[:id])
    permitted = sanitized_plan_schedule_params

    if @plan_schedule.update(permitted.slice(:actual_revenue))
      unless @plan_schedule.has_snapshot?
        @plan_schedule.create_snapshot_from_plan
      end

      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        year: @plan_schedule.scheduled_date.year,
        month: @plan_schedule.scheduled_date.month
      ), notice: t("flash_messages.numerical_managements.messages.actual_revenue_updated")
    else
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
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
    redirect_to company_management_numerical_managements_path(
      company_slug: current_company.slug,
      year: Date.current.year,
      month: Date.current.month
    ),
                alert: I18n.t("api.errors.invalid_date")
    nil
  end

  def create_snapshot_from_products(products_params)
    products_data = products_params.map do |product_id, production_count|
      { product_id: product_id.to_i, production_count: production_count.to_i }
    end

    @plan_schedule.update_products_snapshot(products_data)
  end
end
