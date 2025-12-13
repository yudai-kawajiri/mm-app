# frozen_string_literal: true

class Management::DailyTargetsController < AuthenticatedController
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
    @daily_target.tenant_id ||= current_tenant.id

    @daily_target.assign_attributes(permitted.except(:target_date))

    if @daily_target.save
      message = @daily_target.previously_new_record? ? I18n.t("common.created") : I18n.t("common.updated")
      redirect_to management_numerical_managements_path(month: target_date.strftime("%Y-%m")),
                  notice: I18n.t("numerical_managements.messages.daily_target_saved",
                                date: target_date.strftime("%-m月%-d日"),
                                action: message)
    else
      Rails.logger.error "DailyTarget保存失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to management_numerical_managements_path(month: target_date.strftime("%Y-%m")),
                  alert: I18n.t("numerical_managements.messages.daily_target_save_failed",
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
      redirect_to management_numerical_managements_path(month: target_date.strftime("%Y-%m")),
                  notice: I18n.t("numerical_managements.messages.daily_target_updated_with_date",
                                date: target_date.strftime("%-m月%-d日"))
    else
      Rails.logger.error "DailyTarget更新失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to management_numerical_managements_path(month: target_date.strftime("%Y-%m")),
                  alert: I18n.t("numerical_managements.messages.daily_target_update_failed",
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
    redirect_to management_numerical_managements_path,
                alert: I18n.t("api.errors.invalid_date")
    nil
  end

  def find_monthly_budget_for_date(date)
    # 店舗スコープを適用して月次予算を検索
    monthly_budget = scoped_monthly_budgets.find_by(
      budget_month: date.beginning_of_month
    )

    unless monthly_budget
      redirect_to management_numerical_managements_path(month: date.strftime("%Y-%m")),
                  alert: I18n.t("numerical_managements.messages.budget_not_set")
      return nil
    end

    monthly_budget
  end
end
