class AddTenantAndStoreToDailyTargets < ActiveRecord::Migration[8.1]
  def change
    add_reference :daily_targets, :tenant, null: false, foreign_key: true
    add_reference :daily_targets, :store, null: true, foreign_key: true
  end
end
