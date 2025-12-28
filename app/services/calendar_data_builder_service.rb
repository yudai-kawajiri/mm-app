# frozen_string_literal: true

class CalendarDataBuilderService
  def initialize(year, month, store_id: nil)
    @year = year.to_i
    @month = month.to_i
    @store_id = store_id
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month
  end

  def build
    {
      daily_data: build_daily_array,
      monthly_budget: fetch_monthly_budget,
      daily_targets: fetch_daily_targets_hash
    }
  end

  private

  def build_daily_array
    daily_data_service = DailyDataService.new(@year, @month, store_id: @store_id)
    daily_data_list = daily_data_service.call
    plan_schedules_hash = fetch_plan_schedules_hash

    daily_data_list.map do |day_data|
      date = day_data[:date]
      day_schedules = plan_schedules_hash[date] || []

      {
        date: date,
        actual: day_data[:actual] || 0,
        budget: day_data[:target] || 0,
        target: day_data[:target] || 0,
        planned: day_data[:plan] || 0,
        plan_schedules: day_schedules,
        achievement_rate: day_data[:achievement_rate],
        diff: day_data[:diff] || 0,
        is_today: date == Date.today,
        is_future: date > Date.today
      }
    end
  end

  def fetch_monthly_budget
    query = Management::MonthlyBudget.where(budget_month: Date.new(@year, @month, 1))
    query = query.where(store_id: @store_id) if @store_id.present?
    query.first
  end

  def fetch_daily_targets_hash
    query = Management::DailyTarget.where(target_date: @start_date..@end_date)
    if @store_id.present?
      query = query.joins(:monthly_budget).where(monthly_budgets: { store_id: @store_id })
    end
    query.index_by { |dt| dt.target_date.day }
  end

  def fetch_plan_schedules_hash
    query = Planning::PlanSchedule.where(scheduled_date: @start_date..@end_date)
    query = query.where(store_id: @store_id) if @store_id.present?
    query.group_by(&:scheduled_date)
  end
end
