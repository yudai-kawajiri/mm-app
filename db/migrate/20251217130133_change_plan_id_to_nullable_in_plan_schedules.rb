class ChangePlanIdToNullableInPlanSchedules < ActiveRecord::Migration[7.0]
  def change
    change_column_null :plan_schedules, :plan_id, true
  end
end
