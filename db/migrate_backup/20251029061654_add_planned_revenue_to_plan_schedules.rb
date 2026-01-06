class AddPlannedRevenueToPlanSchedules < ActiveRecord::Migration[8.1]
  def change
    add_column :plan_schedules, :planned_revenue, :integer
  end
end
