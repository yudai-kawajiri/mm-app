class DailyTargetsController < ApplicationController
  before_action :authenticate_user!

  def create
    # パラメータから日付を取得
    target_date_str = params[:daily_target][:target_date]

    unless target_date_str.present?
      redirect_to calendar_numerical_managements_path,
                  alert: '日付が指定されていません。'
      return
    end

    begin
      target_date = Date.parse(target_date_str)
    rescue ArgumentError, TypeError
      redirect_to calendar_numerical_managements_path,
                  alert: '無効な日付形式です。'
      return
    end

    target_amount = params[:daily_target][:target_amount].to_f

    # MonthlyBudgetを取得
    monthly_budget = MonthlyBudget.find_by(
      user: current_user,
      budget_month: target_date.beginning_of_month
    )

    unless monthly_budget
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  alert: 'この月の予算が設定されていません。'
      return
    end

    # ★★★ 既存レコードがあれば更新、なければ新規作成 ★★★
    @daily_target = DailyTarget.find_or_initialize_by(
      user: current_user,
      monthly_budget: monthly_budget,
      target_date: target_date
    )

    @daily_target.target_amount = target_amount

    if @daily_target.save
      message = @daily_target.previously_new_record? ? '作成' : '更新'
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  notice: "#{target_date.strftime('%-m月%-d日')}の目標を#{message}しました。"
    else
      Rails.logger.error "DailyTarget保存失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  alert: "目標の保存に失敗しました: #{@daily_target.errors.full_messages.join(', ')}"
    end
  end

  def update
    # パラメータから日付を取得
    target_date_str = params[:daily_target][:target_date]

    unless target_date_str.present?
      redirect_to calendar_numerical_managements_path,
                  alert: '日付が指定されていません。'
      return
    end

    begin
      target_date = Date.parse(target_date_str)
    rescue ArgumentError, TypeError
      redirect_to calendar_numerical_managements_path,
                  alert: '無効な日付形式です。'
      return
    end

    target_amount = params[:daily_target][:target_amount].to_f

    # 既存レコードを更新
    @daily_target = DailyTarget.find(params[:id])

    # 権限チェック
    unless @daily_target.user_id == current_user.id
      redirect_to calendar_numerical_managements_path,
                  alert: '権限がありません。'
      return
    end

    @daily_target.target_amount = target_amount

    if @daily_target.save
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  notice: "#{target_date.strftime('%-m月%-d日')}の目標を更新しました。"
    else
      Rails.logger.error "DailyTarget更新失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  alert: "目標の更新に失敗しました: #{@daily_target.errors.full_messages.join(', ')}"
    end
  end
end