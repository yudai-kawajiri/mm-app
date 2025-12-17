# frozen_string_literal: true

# MonthlyBudgetsController
#
# 月次予算のCRUD操作を管理
#
# 機能:
#   - 月次予算の作成・更新
#   - 月次予算の削除（日別目標・計画スケジュールも連動）
#   - 実績入力済みスケジュールの保護
#   - 見切率の更新
class Management::MonthlyBudgetsController < Management::BaseController
  include NumericSanitizer

  before_action :authenticate_user!
  before_action :set_monthly_budget, only: [ :update, :destroy, :update_discount_rates ]

  # 月次予算を作成
  #
  # year と month パラメータから budget_month を構築
  #
  # @return [void]
  def create
    budget_month = Date.new(params[:year].to_i, params[:month].to_i, 1)

    # 店舗スコープを適用して予算を検索
    @monthly_budget = scoped_monthly_budgets.find_or_initialize_by(
      budget_month: budget_month
    )
    @monthly_budget.user_id ||= current_user.id
    @monthly_budget.tenant_id ||= current_tenant.id
    @monthly_budget.store_id ||= current_store&.id

    @monthly_budget.assign_attributes(sanitized_monthly_budget_params)

    if @monthly_budget.save
      redirect_to management_numerical_managements_path(year: budget_month.year, month: budget_month.month),
            notice: t("numerical_managements.messages.budget_created")
    else
      redirect_to management_numerical_managements_path(year: budget_month.year, month: budget_month.month),
                  alert: t("numerical_managements.messages.budget_create_failed")
    end
  end

  # 月次予算を更新
  #
  # @return [void]
  def update
    if @monthly_budget.update(sanitized_monthly_budget_params)
      redirect_to management_numerical_managements_path(year: @monthly_budget.budget_month.year, month: @monthly_budget.budget_month.month),
            notice: t("numerical_managements.messages.budget_updated")
    else
      redirect_to management_numerical_managements_path(year: @monthly_budget.budget_month.year, month: @monthly_budget.budget_month.month),
                  alert: t("numerical_managements.messages.budget_update_failed")
    end
  end

  # 月次予算を削除
  #
  # 実績が入力されていない計画スケジュールのみ削除
  # 日別目標は dependent: :destroy で自動削除
  #
  # @return [void]
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

      redirect_to management_numerical_managements_path(year: budget_month.year, month: budget_month.month),
            notice: t("numerical_managements.messages.budget_deleted")
    end
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Monthly budget deletion failed: #{e.message}"
    redirect_to management_numerical_managements_path(year: budget_month.year, month: budget_month.month),
                alert: t("numerical_managements.messages.budget_delete_failed")
  end

  # 見切率を更新
  def update_discount_rates
    # NumericSanitizerを使って全角→半角変換 & サニタイズ
    cleaned_params = sanitize_numeric_params(
      discount_rate_params,
      without_comma: [ :forecast_discount_rate, :target_discount_rate ]
    )

    # 空文字列やnilを0.0に変換
    cleaned_params.transform_values! do |value|
      value.present? ? value : 0.0
    end

    if @monthly_budget.update(cleaned_params)
      redirect_to management_numerical_managements_path(
        year: @monthly_budget.budget_month.year,
        month: @monthly_budget.budget_month.month
      ), notice: t("numerical_managements.messages.discount_rates_updated")
    else
      redirect_to management_numerical_managements_path(
        year: @monthly_budget.budget_month.year,
        month: @monthly_budget.budget_month.month
      ), alert: @monthly_budget.errors.full_messages.join(", ")
    end
  end

  private

  # 月次予算を取得
  #
  # @return [void]
  def set_monthly_budget
    @monthly_budget = Management::MonthlyBudget.find(params[:id])
  end

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def monthly_budget_params
    params.require(:monthly_budget).permit(:target_amount, :description)
  end

  # サニタイズ済みパラメータ
  def sanitized_monthly_budget_params
    sanitize_numeric_params(
      monthly_budget_params,
      with_comma: [ :target_amount ]
    )
  end

  # 見切率用パラメータ
  def discount_rate_params
    param_key = params.key?(:management_monthly_budget) ? :management_monthly_budget : :monthly_budget
    params.require(param_key).permit(:forecast_discount_rate, :target_discount_rate)
  end
end
