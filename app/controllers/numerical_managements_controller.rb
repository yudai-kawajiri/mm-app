class NumericalManagementsController < ApplicationController
  before_action :authenticate_user!

  def index
    # 月選択パラメータの取得（monthまたはtarget_monthに対応）
    month_param = params[:month] || params[:target_month] || Date.today.strftime('%Y-%m')
    @selected_date = Date.parse("#{month_param}-01")

    # MonthlyBudgetを取得
    @budget = MonthlyBudget.find_by(
      user: current_user,
      budget_month: @selected_date.beginning_of_month
    )

    unless @budget
      # 予算が未設定の場合の処理
      @forecast_data = {
        target_amount: 0,
        actual_amount: 0,
        planned_amount: 0,
        forecast_amount: 0,
        remaining_days: 0,
        achievement_rate: 0,
        required_additional: 0,
        daily_required: 0,
        forecast_diff: 0
      }
      @daily_data = []
      return
    end

    # 予測データを取得
    forecast_service = NumericalForecastService.new(current_user, @selected_date.year, @selected_date.month)
    @forecast_data = forecast_service.calculate

    # 日別データを取得
    daily_service = DailyDataService.new(current_user, @selected_date.year, @selected_date.month)
    @daily_data = daily_service.call
  end

  def calendar
    # 月選択パラメータの取得
    month_param = params[:month] || Date.today.strftime('%Y-%m')
    @selected_date = Date.parse("#{month_param}-01")

    # MonthlyBudgetを取得
    @budget = MonthlyBudget.find_by(
      user: current_user,
      budget_month: @selected_date.beginning_of_month
    )

    # カレンダーデータを取得
    calendar_service = CalendarDataService.new(current_user, @selected_date.year, @selected_date.month)
    @calendar_data = calendar_service.call

    # 計画選択用データ（カテゴリでグループ化）
    @plans_by_category = Plan.available_for_schedule
                             .where(user: current_user)
                             .includes(:category)
                             .order('categories.name ASC, plans.created_at DESC')
                             .group_by { |plan| plan.category&.name || '未分類' }
  end

  def update_budget
    @year = params[:year].to_i
    @month = params[:month].to_i
    budget_month = Date.new(@year, @month, 1)

    @budget = MonthlyBudget.find_or_initialize_by(
      user: current_user,
      budget_month: budget_month
    )

    if @budget.update(budget_params)
      # 日別目標を自動生成（まだない場合）
      @budget.generate_daily_targets! unless @budget.daily_targets.exists?

      # リダイレクト先を判定
      redirect_path = if params[:return_to] == 'calendar'
                        calendar_numerical_managements_path(month: "#{@year}-#{@month.to_s.rjust(2, '0')}")
                      else
                        numerical_managements_path(month: "#{@year}-#{@month.to_s.rjust(2, '0')}")
                      end

      redirect_to redirect_path, notice: '予算を更新しました。'
    else
      # 失敗時も同様に判定
      redirect_path = if params[:return_to] == 'calendar'
                        calendar_numerical_managements_path(month: "#{@year}-#{@month.to_s.rjust(2, '0')}")
                      else
                        numerical_managements_path(month: "#{@year}-#{@month.to_s.rjust(2, '0')}")
                      end

      redirect_to redirect_path, alert: '予算の更新に失敗しました。'
    end
  end

  # 月間予算削除機能
  def destroy_budget
    month_param = params[:month] || Date.today.strftime('%Y-%m')
    budget_month = Date.parse("#{month_param}-01").beginning_of_month

    @budget = MonthlyBudget.find_by(
      user: current_user,
      budget_month: budget_month
    )

    if @budget.nil?
      redirect_to numerical_managements_path(month: month_param),
                  alert: '予算が見つかりませんでした。'
      return
    end

    # 権限チェック（念のため）
    unless @budget.user_id == current_user.id
      redirect_to numerical_managements_path(month: month_param),
                  alert: '権限がありません。'
      return
    end

    if @budget.destroy
      redirect_to numerical_managements_path(month: month_param),
                  notice: '予算を削除しました。日別目標も同時に削除されました。'
    else
      redirect_to numerical_managements_path(month: month_param),
                  alert: "予算の削除に失敗しました: #{@budget.errors.full_messages.join(', ')}"
    end
  end

  private

  def budget_params
    params.require(:monthly_budget).permit(:target_amount, :note)
  end
end