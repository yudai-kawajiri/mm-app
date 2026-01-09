# frozen_string_literal: true

# MonthlyBudgetsController
#
# 月次予算のCRUD操作を管理
class Management::MonthlyBudgetsController < Management::BaseController
  include NumericSanitizer

  before_action :authenticate_user!
  before_action :set_monthly_budget, only: [ :update, :destroy, :update_discount_rates ]

  # 月次予算を作成
  def create
    budget_month = Date.new(params[:year].to_i, params[:month].to_i, 1)

    # 店舗スコープを適用して予算を検索
    @monthly_budget = scoped_monthly_budgets.find_or_initialize_by(
      budget_month: budget_month
    )
    @monthly_budget.user_id ||= current_user.id
    @monthly_budget.company_id ||= current_company.id
    @monthly_budget.store_id ||= current_store&.id

    @monthly_budget.assign_attributes(sanitized_monthly_budget_params)

    if @monthly_budget.save
      redirect_to management_numerical_managements_path(
                    year: budget_month.year,
                    month: budget_month.month
                  ), notice: t("flash_messages.numerical_managements.messages.budget_created")
    else
      redirect_to management_numerical_managements_path(
                    year: budget_month.year,
                    month: budget_month.month
                  ), alert: @monthly_budget.errors.full_messages.to_sentence
    end
  end

  # 月次予算を更新
  def update
    if @monthly_budget.update(sanitized_monthly_budget_params)
      redirect_to management_numerical_managements_path(
                    year: @monthly_budget.budget_month.year,
                    month: @monthly_budget.budget_month.month
                  ), notice: t("flash_messages.numerical_managements.messages.budget_updated")
    else
      redirect_to management_numerical_managements_path(
                    year: @monthly_budget.budget_month.year,
                    month: @monthly_budget.budget_month.month
                  ), alert: @monthly_budget.errors.full_messages.to_sentence
    end
  end

  # 月次予算を削除
  def destroy
    budget_month = @monthly_budget.budget_month

    ActiveRecord::Base.transaction do
      start_date = budget_month.beginning_of_month
      end_date = budget_month.end_of_month

      # 実績未入力の計画スケジュールのみ削除
      Planning::PlanSchedule
        .where(scheduled_date: start_date..end_date)
        .where("actual_revenue IS NULL OR actual_revenue = 0")
        .destroy_all

      # 月次予算を削除
      @monthly_budget.destroy!

      redirect_to management_numerical_managements_path(
                    year: budget_month.year,
                    month: budget_month.month
                  ), notice: t("flash_messages.numerical_managements.messages.budget_deleted")
    end
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Monthly budget deletion failed: #{e.message}"
    redirect_to management_numerical_managements_path(
                  year: budget_month.year,
                  month: budget_month.month
                ), alert: t("flash_messages.numerical_managements.messages.budget_delete_failed")
  end

  # 見切率を更新
  def update_discount_rates
    cleaned_params = sanitize_numeric_params(
      discount_rate_params,
      without_comma: [ :forecast_discount_rate, :target_discount_rate ]
    )

    cleaned_params.transform_values! { |value| value.present? ? value : 0.0 }

    if @monthly_budget.update(cleaned_params)
      redirect_to management_numerical_managements_path(
                    year: @monthly_budget.budget_month.year,
                    month: @monthly_budget.budget_month.month
                  ), notice: t("flash_messages.numerical_managements.messages.discount_rates_updated")
    else
      redirect_to management_numerical_managements_path(
                    year: @monthly_budget.budget_month.year,
                    month: @monthly_budget.budget_month.month
                  ), alert: @monthly_budget.errors.full_messages.join(", ")
    end
  end

  private

  def set_monthly_budget
    @monthly_budget = Management::MonthlyBudget.find(params[:id])
  end

  def monthly_budget_params
    params.require(:monthly_budget).permit(:target_amount, :description)
  end

  def sanitized_monthly_budget_params
    sanitize_numeric_params(
      monthly_budget_params,
      with_comma: [ :target_amount ]
    )
  end

  def discount_rate_params
    param_key = params.key?(:management_monthly_budget) ? :management_monthly_budget : :monthly_budget
    params.require(param_key).permit(:forecast_discount_rate, :target_discount_rate)
  end
end