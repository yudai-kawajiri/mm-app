class NumericalManagementsController < AuthenticatedController

  def index
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month

    # 予算取得または初期化
    @monthly_budget = current_user.budget_for_month(@year, @month)
    @monthly_budget ||= current_user.monthly_budgets.build(
      budget_month: Date.new(@year, @month, 1),
      target_amount: 0
    )

    # その月のスケジュール取得
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    @plan_schedules = PlanSchedule.joins(:plan)
                                   .where(plans: { user_id: current_user.id })
                                   .where(scheduled_date: start_date..end_date)
                                   .includes(plan: [:products, :category, :plan_products])
                                   .order(:scheduled_date)

    # 日別サマリー
    @daily_summary = build_daily_summary(@year, @month, @plan_schedules)

    # 統計情報
    @stats = calculate_stats(@monthly_budget)
  end

  # 予算を更新
  def update_budget
    @year = params[:year].to_i
    @month = params[:month].to_i

    @monthly_budget = current_user.budget_for_month(@year, @month)

    if @monthly_budget
      # 既存の予算を更新
      if @monthly_budget.update(budget_params)
        redirect_to numerical_managements_path(year: @year, month: @month), notice: '予算を更新しました'
      else
        redirect_to numerical_managements_path(year: @year, month: @month), alert: '予算の更新に失敗しました'
      end
    else
      # 新規予算を作成
      @monthly_budget = current_user.monthly_budgets.build(budget_params)
      @monthly_budget.budget_month = Date.new(@year, @month, 1)

      if @monthly_budget.save
        redirect_to numerical_managements_path(year: @year, month: @month), notice: '予算を設定しました'
      else
        redirect_to numerical_managements_path(year: @year, month: @month), alert: '予算の設定に失敗しました'
      end
    end
  end

  # 実績を更新
  def update_actual
    @plan_schedule = PlanSchedule.find(params[:id])

    # ユーザーの計画かチェック
    unless @plan_schedule.plan.user_id == current_user.id
      redirect_to numerical_managements_path, alert: '権限がありません'
      return
    end

    if @plan_schedule.update(actual_params)
      redirect_to numerical_managements_path(
        year: @plan_schedule.scheduled_date.year,
        month: @plan_schedule.scheduled_date.month
      ), notice: '実績を更新しました'
    else
      redirect_to numerical_managements_path(
        year: @plan_schedule.scheduled_date.year,
        month: @plan_schedule.scheduled_date.month
      ), alert: '実績の更新に失敗しました'
    end
  end

  private

  def build_daily_summary(year, month, plan_schedules)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    schedules_by_date = plan_schedules.group_by(&:scheduled_date)

    (start_date..end_date).map do |date|
      day_schedules = schedules_by_date[date] || []
      expected = day_schedules.sum(&:expected_revenue)
      actual = day_schedules.sum { |ps| ps.actual_revenue || 0 }

      {
        date: date,
        schedules: day_schedules,
        expected_revenue: expected,
        actual_revenue: actual,
        variance: actual - expected,
        has_schedules: day_schedules.any?,
        has_actual: day_schedules.any?(&:has_actual?),
        is_today: date == Date.current,
        is_past: date < Date.current,
        is_future: date > Date.current
      }
    end
  end

  def calculate_stats(monthly_budget)
    if monthly_budget.persisted?
      {
        total_planned: monthly_budget.total_planned_revenue,
        total_actual: monthly_budget.total_actual_revenue,
        total_forecast: monthly_budget.total_forecast_revenue,
        achievement_rate: monthly_budget.achievement_rate,
        budget_variance: monthly_budget.budget_variance
      }
    else
      {
        total_planned: 0,
        total_actual: 0,
        total_forecast: 0,
        achievement_rate: 0,
        budget_variance: 0
      }
    end
  end

  def budget_params
    params.require(:monthly_budget).permit(:target_amount, :note)
  end

  def actual_params
    params.require(:plan_schedule).permit(:actual_revenue, :note)
  end
end