class ChangeActualRevenueToIntegerInPlanSchedules < ActiveRecord::Migration[8.1]
  def up
    change_column :plan_schedules, :actual_revenue, :bigint, using: 'actual_revenue::bigint'
  end

  def down
    change_column :plan_schedules, :actual_revenue, :decimal, precision: 12, scale: 2
  end
end
