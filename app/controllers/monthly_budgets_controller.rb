# app/controllers/monthly_budgets_controller.rb
class MonthlyBudgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_monthly_budget, only: [:update, :destroy]

  def create
    # year と month パラメータから budget_month を構築
    budget_month = Date.new(params[:year].to_i, params[:month].to_i, 1)

    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: budget_month
    )

    @monthly_budget.assign_attributes(monthly_budget_params)

    if @monthly_budget.save
      redirect_to redirect_to_appropriate_page(budget_month),
                  notice: t('numerical_managements.messages.budget_created')
    else
      redirect_to redirect_to_appropriate_page(budget_month),
                  alert: t('numerical_managements.messages.budget_create_failed')
    end
  end

  def update
    if @monthly_budget.update(monthly_budget_params)
      redirect_to redirect_to_appropriate_page(@monthly_budget.budget_month),
                  notice: t('numerical_managements.messages.budget_updated')
    else
      redirect_to redirect_to_appropriate_page(@monthly_budget.budget_month),
                  alert: t('numerical_managements.messages.budget_update_failed')
    end
  end

  def destroy
    budget_month = @monthly_budget.budget_month

    if @monthly_budget.destroy
      redirect_to redirect_to_appropriate_page(budget_month),
                  notice: t('numerical_managements.messages.budget_deleted')
    else
      redirect_to redirect_to_appropriate_page(budget_month),
                  alert: t('numerical_managements.messages.budget_delete_failed')
    end
  end

  private

  def set_monthly_budget
    @monthly_budget = current_user.monthly_budgets.find(params[:id])
  end

  def monthly_budget_params
    params.require(:monthly_budget).permit(:target_amount, :note)
  end

  # リダイレクト先を判定（index画面 or calendar画面）
  def redirect_to_appropriate_page(budget_month)
    month_param = budget_month.strftime('%Y-%m')

    if params[:return_to] == 'calendar'
      calendar_numerical_managements_path(month: month_param)
    else
      numerical_managements_path(month: month_param)
    end
  end
end
