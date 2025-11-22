# frozen_string_literal: true

# MonthlyBudgetsController
#
# 月次予算のCRUD操作を管理
#
# 機能:
#   - 月次予算の作成・更新
#   - 月次予算の削除（日別目標・計画スケジュールも連動）
#   - 実績入力済みスケジュールの保護
class Management::MonthlyBudgetsController < ApplicationController
  include NumericSanitizer

  before_action :authenticate_user!
  before_action :set_monthly_budget, only: [:update, :destroy]

  # 月次予算を作成
  #
  # year と month パラメータから budget_month を構築
  #
  # @return [void]
  def create
    budget_month = Date.new(params[:year].to_i, params[:month].to_i, 1)

    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: budget_month
    )

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
      current_user.plan_schedules
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
  private

  # 月次予算を取得
  #
  # @return [void]
  def set_monthly_budget
    @monthly_budget = current_user.monthly_budgets.find(params[:id])
  end

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def monthly_budget_params
    params.require(:monthly_budget).permit(:target_amount, :description)
  end

  # サニタイズ済みパラメータ
  #
  # NumericSanitizerで全角→半角、カンマ削除、スペース削除
  #
  # @return [ActionController::Parameters]
  def sanitized_monthly_budget_params
    sanitize_numeric_params(
      monthly_budget_params,
      with_comma: [:target_amount]
    )
  end
end
