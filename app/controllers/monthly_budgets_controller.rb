# app/controllers/monthly_budgets_controller.rb
class MonthlyBudgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_monthly_budget, only: [ :update, :destroy ]

  def create
    # year と month パラメータから budget_month を構築
    budget_month = Date.new(params[:year].to_i, params[:month].to_i, 1)

    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: budget_month
    )

    @monthly_budget.assign_attributes(monthly_budget_params)

    if @monthly_budget.save
      redirect_to numerical_managements_path(month: budget_month.strftime("%Y-%m")),
                  notice: t("numerical_managements.messages.budget_created")
    else
      redirect_to numerical_managements_path(month: budget_month.strftime("%Y-%m")),
                  alert: t("numerical_managements.messages.budget_create_failed")
    end
  end

  def update
    if @monthly_budget.update(monthly_budget_params)
      redirect_to numerical_managements_path(month: @monthly_budget.budget_month.strftime("%Y-%m")),
                  notice: t("numerical_managements.messages.budget_updated")
    else
      redirect_to numerical_managements_path(month: @monthly_budget.budget_month.strftime("%Y-%m")),
                  alert: t("numerical_managements.messages.budget_update_failed")
    end
  end

  def destroy
    budget_month = @monthly_budget.budget_month

    ActiveRecord::Base.transaction do
      start_date = budget_month.beginning_of_month
      end_date = budget_month.end_of_month

      # 実績が入力されていない計画スケジュールのみ削除
      # (actual_revenue が nil または 0 のもの)
      current_user.plan_schedules
                  .where(scheduled_date: start_date..end_date)
                  .where("actual_revenue IS NULL OR actual_revenue = 0")
                  .destroy_all

      # 月次予算を削除（日別目標は dependent: :destroy で自動削除）
      @monthly_budget.destroy!

      redirect_to numerical_managements_path(month: budget_month.strftime("%Y-%m")),
                  notice: t("numerical_managements.messages.budget_deleted")
    end
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Monthly budget deletion failed: #{e.message}"
    redirect_to numerical_managements_path(month: budget_month.strftime("%Y-%m")),
                alert: t("numerical_managements.messages.budget_delete_failed")
  end

  private

  def set_monthly_budget
    @monthly_budget = current_user.monthly_budgets.find(params[:id])
  end

  def monthly_budget_params
    params.require(:monthly_budget).permit(:target_amount, :note)
  end
end
