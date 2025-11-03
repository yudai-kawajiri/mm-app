class NumericalManagementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_year_month, only: [
    :index,
    :update_monthly_budget,
    :destroy_monthly_budget,
    :bulk_update
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
      current_user,
      @year,
      @month
    )

    @forecast_data = @forecast_service.calculate
    @daily_data = build_daily_data(start_date, end_date)

    # 計画一覧（カテゴリ別）- モーダルで使用
    @plans_by_category = current_user.plans
                                      .includes(:category)
                                      .where(status: :active)
                                      .group_by { |plan| plan.category&.name || '未分類' }
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
        scheduled_date: scheduled_date,
        planned_revenue: plan.expected_revenue
      )

      if @plan_schedule.save
        redirect_to numerical_managements_path(month: "#{params[:year]}-#{params[:month]}"),
                    notice: t("numerical_managements.messages.plan_assigned")
      else
        redirect_to numerical_managements_path(month: "#{params[:year]}-#{params[:month]}"),
                    alert: t("numerical_managements.messages.plan_assign_failed")
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to numerical_managements_path(month: "#{params[:year]}-#{params[:month]}"),
                  alert: t("numerical_managements.messages.plan_not_found")
    end
  end

  def unassign_plan
    @plan_schedule = current_user.plan_schedules.find(params[:id])

    year = @plan_schedule.scheduled_date.year
    month = @plan_schedule.scheduled_date.month

    if @plan_schedule.destroy
      redirect_to numerical_managements_path(month: "#{year}-#{month}"),
                  notice: t("numerical_managements.messages.plan_unassigned")
    else
      redirect_to numerical_managements_path(month: "#{year}-#{month}"),
                  alert: t("numerical_managements.messages.plan_unassign_failed")
    end
  end

  def update_monthly_budget
    @selected_date = Date.new(params[:year].to_i, params[:month].to_i, 1)

    @monthly_budget = current_user.monthly_budgets.find_or_initialize_by(
      budget_month: @selected_date
    )

    if @monthly_budget.update(target_amount: params[:monthly_budget][:target_amount])
      # 既存の日別目標を削除
      current_user.daily_targets
                  .where(target_date: @selected_date..@selected_date.end_of_month)
                  .delete_all

      # 日別目標を自動生成
      @monthly_budget.generate_daily_targets!

      redirect_to numerical_managements_path(month: "#{params[:year]}-#{params[:month]}"),
                  notice: t('numerical_managements.messages.budget_updated')
    else
      redirect_to numerical_managements_path(month: "#{params[:year]}-#{params[:month]}"),
                  alert: t('numerical_managements.messages.budget_update_failed')
    end
  end

  def destroy_monthly_budget
    @selected_date = Date.new(params[:year].to_i, params[:month].to_i, 1)

    @monthly_budget = current_user.monthly_budgets.find_by(
      budget_month: @selected_date
    )

    if @monthly_budget&.destroy
      # 関連する日別目標も削除される（dependent: :destroy）
      redirect_to numerical_managements_path(month: "#{params[:year]}-#{params[:month]}"),
                  notice: t('numerical_managements.messages.budget_deleted')
    else
      redirect_to numerical_managements_path(month: "#{params[:year]}-#{params[:month]}"),
                  alert: t('numerical_managements.messages.budget_delete_failed')
    end
  end

  def bulk_update
    begin
      ActiveRecord::Base.transaction do
        daily_data_params = params[:daily_data] || []

        daily_data_params.each do |index, data|
          date = Date.parse(data[:date])

          # 1. 日別目標の更新/作成
          if data[:target_amount].present?
            target_amount = data[:target_amount].to_i

            if data[:target_id].present?
              daily_target = current_user.daily_targets.find(data[:target_id])
              daily_target.update!(target_amount: target_amount)
            else
              current_user.daily_targets.create!(
                target_date: date,
                target_amount: target_amount
              )
            end
          end

          # 2. 実績の更新
          if data[:actual_revenue].present? && data[:plan_schedule_id].present?
            plan_schedule = current_user.plan_schedules.find(data[:plan_schedule_id])
            plan_schedule.update!(actual_revenue: data[:actual_revenue].to_i)
          end
        end

        month_param = params[:month]
        redirect_to numerical_managements_path(month: month_param),
                    notice: '一括更新が完了しました'
      end
    rescue ActiveRecord::RecordInvalid => e
      month_param = params[:month]
      redirect_to numerical_managements_path(month: month_param),
                  alert: "更新に失敗しました: #{e.record.errors.full_messages.join(', ')}"
    rescue ActiveRecord::RecordNotFound => e
      month_param = params[:month]
      redirect_to numerical_managements_path(month: month_param),
                  alert: "指定されたレコードが見つかりません"
    rescue => e
      month_param = params[:month]
      redirect_to numerical_managements_path(month: month_param),
                  alert: "予期しないエラーが発生しました: #{e.message}"
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
    (start_date..end_date).map do |date|
      day = date.day
      daily_target = @daily_targets[day]

      plan_schedules = current_user.plan_schedules
                                    .where(scheduled_date: date)
                                    .includes(plan: { plan_products: :product })

      planned_revenue = plan_schedules.sum do |ps|
        ps.plan.plan_products.sum { |pp| pp.product.price * pp.production_count }
      end

      actual_revenue = plan_schedules.where.not(actual_revenue: nil).sum(:actual_revenue)

      # 達成率と差分を計算
      target_amount = daily_target&.target_amount || 0
      achievement_rate = target_amount.positive? ? ((actual_revenue.to_f / target_amount) * 100).round(1) : 0.0
      diff = actual_revenue - target_amount
      forecast = actual_revenue # 簡易予測（実績をそのまま使用）

      {
        date: date,
        target: target_amount,
        planned: planned_revenue,
        actual: actual_revenue,
        forecast: forecast,
        diff: diff,
        achievement_rate: achievement_rate,
        plan_schedules: plan_schedules
      }
    end
  end

  def daily_target_params
    params.require(:daily_target).permit(:target_amount, :note)
  end
end
