# app/controllers/monthly_budgets_controller.rb
class MonthlyBudgetsController < ApplicationController
  before_action :set_monthly_budget, only: [:update]

  def create
    @budget = MonthlyBudget.new(monthly_budget_params)
    @budget.user = current_user
    @budget.budget_month = Date.parse("#{params[:monthly_budget][:budget_month]}-01")  # ← -01 を追加

    if @budget.save
      # 日別目標の自動生成
      if params[:monthly_budget][:generate_daily_targets] == "1"
        @budget.generate_daily_targets!
      end

      redirect_to numerical_managements_path(month: @budget.budget_month.strftime('%Y-%m')),
                  notice: "月間予算を設定しました。"
    else
      redirect_to numerical_managements_path,
                  alert: "月間予算の設定に失敗しました: #{@budget.errors.full_messages.join(', ')}"
    end
  end

  def update
    @budget.assign_attributes(monthly_budget_params)
    @budget.budget_month = Date.parse("#{params[:monthly_budget][:budget_month]}-01")  # ← -01 を追加

    if @budget.save
      # 日別目標の自動生成（既存のものは削除して再生成）
      if params[:monthly_budget][:generate_daily_targets] == "1"
        @budget.daily_targets.destroy_all
        @budget.generate_daily_targets!
      end

      redirect_to numerical_managements_path(month: @budget.budget_month.strftime('%Y-%m')),
                  notice: "月間予算を更新しました。"
    else
      redirect_to numerical_managements_path,
                  alert: "月間予算の更新に失敗しました: #{@budget.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_monthly_budget
    @budget = MonthlyBudget.find(params[:id])
  end

  def monthly_budget_params
    params.require(:monthly_budget).permit(:target_amount)
  end
end
