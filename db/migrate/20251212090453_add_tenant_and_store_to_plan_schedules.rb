class AddTenantAndStoreToPlanSchedules < ActiveRecord::Migration[8.1]
  def change
    add_reference :plan_schedules, :tenant, null: false, foreign_key: true
    add_reference :plan_schedules, :store, null: true, foreign_key: true
  end
end
