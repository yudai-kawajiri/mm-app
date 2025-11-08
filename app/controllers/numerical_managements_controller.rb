class NumericalManagementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_year_month, only: [
    :index,
    :calendar,
    :update_monthly_budget,
    :destroy_monthly_budget
  ]

  def index
    @selected_date = Date.new(@year, @month, 1)
    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: @selected_date
    )

    start_date = @selected_date
    end_date = Date.new(@year, @month, -1)

    @daily_targets = current_user.daily_targets
                                  .where(target_date: start_date..end_date)
                                  .index_by { |dt| dt.target_date.day }

    @days_in_month = end_date.day

    @forecast_service = NumericalForecastService.new(
      user: current_user,
      year: @year,
      month: @month
    )

    @forecast_data = @forecast_service.calculate
    @daily_data = build_daily_data(start_date, end_date)

    # 計画一覧（カテゴリ別）- モーダルで使用
    @plans_by_category = current_user.plans
                                      .includes(:category)
                                      .where(status: :active)
                                      .group_by { |plan| plan.category&.name || I18n.t('common.uncategorized') }
  end

  def calendar
    @selected_date = Date.new(@year, @month, 1)

    @calendar_service = CalendarDataService.new(
      current_user,
      @year,
      @month
    )

    @calendar_data = @calendar_service.call
    @monthly_budget = @calendar_service.budget
    @budget = @monthly_budget
    @categories = current_user.categories.order(:name)

    @plans_by_category = current_user.plans
                                    .includes(:category)
                                    .where(status: :active)
                                    .group_by { |plan| plan.category.name }
  end

  def update_daily_target
    target_date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    @daily_target = current_user.daily_targets.find_or_initialize_by(
      target_date: target_date
    )

    # 月次予算を取得
    selected_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
    monthly_budget = current_user.monthly_budgets.find_by(budget_month: selected_date)

    # 月次予算が存在しない場合はエラー
    unless monthly_budget
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.budget_not_set')
      return
    end

    # 予算超過チェック
    new_target_amount = daily_target_params[:target_amount].to_i

    # この日以外の日別予算の合計を計算
    other_targets_sum = current_user.daily_targets
                                    .where(target_date: selected_date..selected_date.end_of_month)
                                    .where.not(id: @daily_target.id)
                                    .sum(:target_amount)

    total_target = other_targets_sum + new_target_amount

    # 予算超過チェック
    if total_target > monthly_budget.target_amount
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.budget_mismatch',
                          budget: view_context.number_to_currency(monthly_budget.target_amount, unit: "¥", precision: 0),
                          total: view_context.number_to_currency(total_target, unit: "¥", precision: 0))
      return
    end

    # monthly_budget_id を設定
    @daily_target.monthly_budget = monthly_budget

    if @daily_target.update(daily_target_params)
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t("numerical_managements.messages.daily_target_updated")
    else
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t("numerical_managements.messages.daily_target_update_failed")
    end
  end

  def destroy_daily_target
    target_date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    @daily_target = current_user.daily_targets.find_by(
      target_date: target_date
    )

    if @daily_target&.destroy
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t("numerical_managements.messages.daily_target_deleted")
    else
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t("numerical_managements.messages.daily_target_delete_failed")
    end
  end

  def assign_plan
    begin
      plan = current_user.plans.find(params[:plan_id])

      scheduled_date = Date.new(
        params[:year].to_i,
        params[:month].to_i,
        params[:day].to_i
      )

      @plan_schedule = current_user.plan_schedules.new(
        plan: plan,
        scheduled_date: scheduled_date
      )

      if @plan_schedule.save
        redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                    notice: t("numerical_managements.messages.plan_assigned")
      else
        redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                    alert: t("numerical_managements.messages.plan_assign_failed")
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to calendar_numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t("api.errors.plan_not_found")
    end
  end

  def unassign_plan
    @plan_schedule = current_user.plan_schedules.find(params[:id])

    if @plan_schedule.destroy
      redirect_to calendar_numerical_managements_path(
        year: @plan_schedule.year,
        month: @plan_schedule.month
      ), notice: t("numerical_managements.messages.plan_unassigned")
    else
      redirect_to calendar_numerical_managements_path(
        year: @plan_schedule.year,
        month: @plan_schedule.month
      ), alert: t("numerical_managements.messages.plan_unassign_failed")
    end
  end

  def update_monthly_budget
    @selected_date = Date.new(params[:year].to_i, params[:month].to_i, 1)

    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: @selected_date
    )

    if @monthly_budget.update(target_amount: params[:monthly_budget][:target_amount])
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t('numerical_managements.messages.budget_updated')
    else
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.budget_update_failed')
    end
  end

  def destroy_monthly_budget
    @selected_date = Date.new(params[:year].to_i, params[:month].to_i, 1)

    @monthly_budget = current_user.monthly_budgets.find_by(
      budget_month: @selected_date
    )

    if @monthly_budget&.destroy
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t('numerical_managements.messages.budget_deleted')
    else
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.budget_delete_failed')
    end
  end

  def bulk_update
    # パラメータ検証
    unless params[:daily_data].present?
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('api.errors.invalid_parameters')
      return
    end

    # 月次予算を取得
    selected_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
    monthly_budget = current_user.monthly_budgets.find_by(budget_month: selected_date)

    # 月次予算が存在しない場合はエラー
    unless monthly_budget
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.budget_not_set')
      return
    end

    # 日別目標の合計を計算
    total_target = 0
    params[:daily_data].each do |index, attributes|
      total_target += attributes[:target_amount].to_i
    end

    # 月次予算を超過する場合のみエラー
    if total_target > monthly_budget.target_amount
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.budget_mismatch',
                          budget: view_context.number_to_currency(monthly_budget.target_amount, unit: "¥", precision: 0),
                          total: view_context.number_to_currency(total_target, unit: "¥", precision: 0))
      return
    end

    success_count = 0
    error_count = 0

    params[:daily_data].each do |index, attributes|
      # 日付を取得
      target_date = Date.parse(attributes[:date])

      # 必ず monthly_budget_id を設定
      if attributes[:target_id].present?
        daily_target = current_user.daily_targets.find_by(id: attributes[:target_id])
        if daily_target
          daily_target.monthly_budget = monthly_budget  # 既存レコードにも設定
        end
      else
        daily_target = current_user.daily_targets.find_or_initialize_by(
          target_date: target_date
        )
        daily_target.monthly_budget = monthly_budget  # 新規レコードに設定
      end

      if daily_target && daily_target.update(target_amount: attributes[:target_amount])
        success_count += 1
      else
        error_count += 1
        Rails.logger.error "DailyTarget update failed: #{daily_target&.errors&.full_messages}"
      end

      # 実績の更新
      if attributes[:plan_schedule_id].present? && attributes[:actual_revenue].present?
        plan_schedule = current_user.plan_schedules.find_by(id: attributes[:plan_schedule_id])
        if plan_schedule
          plan_schedule.update(actual_revenue: attributes[:actual_revenue])
        end
      end
    end

    if error_count.zero?
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  notice: t('numerical_managements.messages.daily_details_updated')
    else
      redirect_to numerical_managements_path(year: params[:year], month: params[:month]),
                  alert: t('numerical_managements.messages.update_failed')
    end
  end

  private

  def set_year_month
    if params[:month]&.include?("-")
      date_parts = params[:month].split("-")
      @year = date_parts[0].to_i
      @month = date_parts[1].to_i
    else
      @year = params[:year]&.to_i || Date.current.year
      @month = params[:month]&.to_i || Date.current.month
    end
  end

  def build_daily_data(start_date, end_date)
    cumulative_target = 0
    cumulative_actual = 0
    cumulative_planned = 0

    (start_date..end_date).map do |date|
      day = date.day
      daily_target = @daily_targets[day]

      plan_schedules = current_user.plan_schedules
                                   .includes(:plan)
                                   .where(scheduled_date: date)

      planned_revenue = plan_schedules.sum { |ps| ps.current_planned_revenue }
      actual_revenue = plan_schedules.where.not(actual_revenue: nil).sum(:actual_revenue)

      target_amount = daily_target&.target_amount || 0
      achievement_rate = target_amount.positive? ? ((actual_revenue.to_f / target_amount) * 100).round(1) : 0.0
      diff = actual_revenue - target_amount

      cumulative_target += target_amount
      cumulative_actual += actual_revenue
      cumulative_planned += planned_revenue
      cumulative_achievement_rate = cumulative_target.positive? ? ((cumulative_actual.to_f / cumulative_target) * 100).round(1) : 0.0
      cumulative_diff = cumulative_actual - cumulative_target

      {
        date: date,
        target: target_amount,
        actual: actual_revenue,
        achievement_rate: achievement_rate,
        diff: diff,
        cumulative_target: cumulative_target,
        cumulative_actual: cumulative_actual,
        cumulative_achievement_rate: cumulative_achievement_rate,
        cumulative_diff: cumulative_diff,
        cumulative_planned: cumulative_planned,
        planned: planned_revenue,
        plan_schedules: plan_schedules
      }
    end
  end

  def daily_target_params
    params.require(:daily_target).permit(:target_amount, :note)
  end
end
