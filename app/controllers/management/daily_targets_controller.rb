# frozen_string_literal: true

class Management::DailyTargetsController < Management::BaseController
  include NumericSanitizer

  def create
    permitted = sanitized_daily_target_params
    target_date = parse_target_date(permitted[:target_date])
    return unless target_date

    monthly_budget = find_monthly_budget_for_date(target_date)
    return unless monthly_budget

    @daily_target = Management::DailyTarget.find_or_initialize_by(
      monthly_budget: monthly_budget,
      target_date: target_date
    )
    @daily_target.user_id ||= current_user.id
    @daily_target.store_id ||= current_store&.id
    @daily_target.company_id ||= current_company.id

    @daily_target.assign_attributes(permitted.except(:target_date))

    if @daily_target.save
      action = @daily_target.previously_new_record? ? "created" : "updated"
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        month: target_date.strftime("%Y-%m")
      ), notice: I18n.t("flash_messages.numerical_managements.messages.daily_target_saved",
                        date: I18n.l(target_date, format: :short_with_day),
                        action: I18n.t("flash_messages.numerical_managements.actions.#{action}"))
    else
      Rails.logger.error "DailyTarget保存失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        month: target_date.strftime("%Y-%m")
      ), alert: I18n.t("flash_messages.numerical_managements.messages.daily_target_save_failed",
                       errors: @daily_target.errors.full_messages.join(", "))
    end
  end

  def update
    permitted = sanitized_daily_target_params
    target_date = parse_target_date(permitted[:target_date])
    return unless target_date

    @daily_target = Management::DailyTarget.find(params[:id])

    @daily_target.assign_attributes(permitted.except(:target_date))

    if @daily_target.save
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        month: target_date.strftime("%Y-%m")
      ), notice: I18n.t("flash_messages.numerical_managements.messages.daily_target_updated_with_date",
                        date: I18n.l(target_date, format: :short_with_day))
    else
      Rails.logger.error "DailyTarget更新失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        month: target_date.strftime("%Y-%m")
      ), alert: I18n.t("flash_messages.numerical_managements.messages.daily_target_update_failed",
                       errors: @daily_target.errors.full_messages.join(", "))
    end
  end

  private

  def daily_target_params
    params.require(:daily_target).permit(:target_date, :target_amount)
  end

  def sanitized_daily_target_params
    sanitize_numeric_params(
      daily_target_params,
      with_comma: [ :target_amount ]
    )
  end

  def parse_target_date(date_string)
    return nil unless date_string.present?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    redirect_to company_management_numerical_managements_path(company_slug: current_company.slug),
                alert: I18n.t("flash_messages.api.errors.invalid_date")
    nil
  end

  def find_monthly_budget_for_date(date)
    monthly_budget = scoped_monthly_budgets.find_by(
      budget_month: date.beginning_of_month
    )

    unless monthly_budget
      redirect_to company_management_numerical_managements_path(
        company_slug: current_company.slug,
        month: date.strftime("%Y-%m")
      ), alert: I18n.t("flash_messages.numerical_managements.messages.budget_not_set")
      return nil
    end

    monthly_budget
  end
end
