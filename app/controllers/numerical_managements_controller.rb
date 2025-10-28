class NumericalManagementsController < AuthenticatedController
  before_action :set_date_range, only: [:index, :calendar]
  before_action :set_monthly_budget, only: [:index, :calendar]

  # 既存の一覧ビュー（テーブル表示）
  def index
    load_plan_schedules
    build_daily_summary
  end

  # 新規追加: カレンダービュー
  def calendar
    load_plan_schedules
    build_calendar_data
    load_available_plans
  end

  # 予算の登録・更新
  def update_budget
    @budget = current_user.budget_for_month(params[:budget_month])

    if @budget
      # 既存予算の更新
      if @budget.update(budget_params)
        redirect_to numerical_managements_path(year: @budget.budget_month.year, month: @budget.budget_month.month),
                    notice: '予算を更新しました'
      else
        redirect_to numerical_managements_path, alert: '予算の更新に失敗しました'
      end
    else
      # 新規予算の作成
      @budget = current_user.monthly_budgets.build(budget_params)
      if @budget.save
        redirect_to numerical_managements_path(year: @budget.budget_month.year, month: @budget.budget_month.month),
                    notice: '予算を設定しました'
      else
        redirect_to numerical_managements_path, alert: '予算の設定に失敗しました'
      end
    end
  end

  # 実績の更新
  def update_actual
    @plan_schedule = PlanSchedule.find(params[:id])

    # 権限チェック
    unless @plan_schedule.plan.user_id == current_user.id
      redirect_to numerical_managements_path, alert: '権限がありません'
      return
    end

    if @plan_schedule.update(actual_params)
      respond_to do |format|
        format.html { redirect_to numerical_managements_path(year: @plan_schedule.scheduled_date.year, month: @plan_schedule.scheduled_date.month), notice: '実績を更新しました' }
        format.turbo_stream
      end
    else
      redirect_to numerical_managements_path, alert: '実績の更新に失敗しました'
    end
  end

  # 新規追加: 計画をカレンダーに配置
  def assign_plan_to_date
    plan = current_user.plans.find(params[:plan_id])
    scheduled_date = Date.parse(params[:scheduled_date])

    # 既に配置されているか確認
    if plan.plan_schedules.exists?(scheduled_date: scheduled_date)
      render json: { error: 'この日付には既に配置されています' }, status: :unprocessable_entity
      return
    end

    plan_schedule = plan.plan_schedules.create(scheduled_date: scheduled_date)

    if plan_schedule.persisted?
      respond_to do |format|
        format.turbo_stream
        format.json { render json: { success: true, plan_schedule: plan_schedule } }
      end
    else
      render json: { error: plan_schedule.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def set_date_range
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i || Date.current.month
    @current_date = Date.new(year, month, 1)
    @start_date = @current_date.beginning_of_month
    @end_date = @current_date.end_of_month
    # index.html.erbで使用するため
    @year = year
    @month = month
  end

  def set_monthly_budget
    @budget = current_user.budget_for_month(@current_date)
    # index.html.erbでform_with modelに渡すために@monthly_budgetを初期化
    # 予算が存在しない場合はbuildで新規インスタンスを作成
    @monthly_budget = @budget || current_user.monthly_budgets.build(
      budget_month: @current_date,
      target_amount: 0
    )
  end

  def load_plan_schedules
    @plan_schedules = PlanSchedule.joins(:plan)
                                   .where(plans: { user_id: current_user.id })
                                   .where(scheduled_date: @start_date..@end_date)
                                   .includes(plan: [:plan_products, :category])
                                   .order(:scheduled_date)
  end

  def build_daily_summary
    @daily_summary = []

    (@start_date..@end_date).each do |date|
      day_schedules = @plan_schedules.select { |ps| ps.scheduled_date == date }

      planned_revenue = day_schedules.sum { |ps| ps.expected_revenue }
      actual_revenue = day_schedules.sum { |ps| ps.actual_revenue || 0 }
      variance = actual_revenue - planned_revenue

      @daily_summary << {
        date: date,
        schedules: day_schedules,
        planned_revenue: planned_revenue,
        actual_revenue: actual_revenue,
        variance: variance
      }
    end
  end

  def build_calendar_data
    @calendar_weeks = []
    calendar_start = @start_date.beginning_of_week(:sunday)
    calendar_end = @end_date.end_of_week(:sunday)

    current_week = []
    (calendar_start..calendar_end).each do |date|
      day_schedules = @plan_schedules.select { |ps| ps.scheduled_date == date }

      current_week << {
        date: date,
        in_current_month: date.month == @current_date.month,
        schedules: day_schedules,
        planned_revenue: day_schedules.sum { |ps| ps.expected_revenue },
        actual_revenue: day_schedules.sum { |ps| ps.actual_revenue || 0 }
      }

      if date.wday == 6 # 土曜日
        @calendar_weeks << current_week
        current_week = []
      end
    end
  end

  def load_available_plans
    @available_plans = current_user.plans
                                   .includes(:category, :plan_products)
                                   .where(status: :completed)
                                   .order(created_at: :desc)
  end

  def budget_params
    params.require(:monthly_budget).permit(:target_amount, :budget_month)
  end

  def actual_params
    params.require(:plan_schedule).permit(:actual_revenue, :note)
  end
end
