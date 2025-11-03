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
      # 日別目標を自動生成
      regenerate_daily_targets(@monthly_budget)

      redirect_to numerical_managements_path(month: budget_month.strftime("%Y-%m")),
                  notice: t("numerical_managements.messages.budget_created")
    else
      redirect_to numerical_managements_path(month: budget_month.strftime("%Y-%m")),
                  alert: t("numerical_managements.messages.budget_create_failed")
    end
  end

  def update
    if @monthly_budget.update(monthly_budget_params)
      # 日別目標を再生成
      regenerate_daily_targets(@monthly_budget)

      redirect_to numerical_managements_path(month: @monthly_budget.budget_month.strftime("%Y-%m")),
                  notice: t("numerical_managements.messages.budget_updated")
    else
      redirect_to numerical_managements_path(month: @monthly_budget.budget_month.strftime("%Y-%m")),
                  alert: t("numerical_managements.messages.budget_update_failed")
    end
  end

  def destroy
    budget_month = @monthly_budget.budget_month

    if @monthly_budget.destroy
      redirect_to numerical_managements_path(month: budget_month.strftime("%Y-%m")),
                  notice: t("numerical_managements.messages.budget_deleted")
    else
      redirect_to numerical_managements_path(month: budget_month.strftime("%Y-%m")),
                  alert: t("numerical_managements.messages.budget_delete_failed")
    end
  end

  private

  def set_monthly_budget
    @monthly_budget = current_user.monthly_budgets.find(params[:id])
  end

  def monthly_budget_params
    params.require(:monthly_budget).permit(:target_amount, :note)
  end

  # 日別目標を再生成
  def regenerate_daily_targets(monthly_budget)
    start_date = monthly_budget.budget_month
    end_date = start_date.end_of_month

    # 既存の日別目標を削除
    current_user.daily_targets
                .where(target_date: start_date..end_date)
                .delete_all

    # MonthlyBudget モデルのメソッドを使用して日別目標を生成
    monthly_budget.generate_daily_targets!
  end
end
