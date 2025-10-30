class DailyTargetsController < ApplicationController
  before_action :authenticate_user!

  def create
    target_date = Date.parse(params[:daily_target][:target_date])
    target_amount = params[:daily_target][:target_amount].to_f

    # MonthlyBudgetを取得
    monthly_budget = MonthlyBudget.find_by(
      user: current_user,
      budget_month: target_date.beginning_of_month
    )

    unless monthly_budget
      redirect_to calendar_numerical_managements_path(date: target_date),
                  alert: 'この月の予算が設定されていません。'
      return
    end

    # 新規作成
    @daily_target = DailyTarget.new(
      user: current_user,
      monthly_budget: monthly_budget,
      target_date: target_date,
      target_amount: target_amount
    )

    if @daily_target.save
      redirect_to calendar_numerical_managements_path(date: target_date),
                  notice: "#{target_date.strftime('%-m月%-d日')}の目標を作成しました。"
    else
      redirect_to calendar_numerical_managements_path(date: target_date),
                  alert: "目標の作成に失敗しました: #{@daily_target.errors.full_messages.join(', ')}"
    end
  end

  def update
    target_date = Date.parse(params[:daily_target][:target_date])
    target_amount = params[:daily_target][:target_amount].to_f

    # 既存レコードを更新
    @daily_target = DailyTarget.find(params[:id])
    @daily_target.target_amount = target_amount

    if @daily_target.save
      redirect_to calendar_numerical_managements_path(date: target_date),
                  notice: "#{target_date.strftime('%-m月%-d日')}の目標を更新しました。"
    else
      redirect_to calendar_numerical_managements_path(date: target_date),
                  alert: "目標の更新に失敗しました: #{@daily_target.errors.full_messages.join(', ')}"
    end
  end
end
