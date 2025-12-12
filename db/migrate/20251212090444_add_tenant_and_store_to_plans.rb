class AddTenantAndStoreToPlans < ActiveRecord::Migration[8.1]
  def change
    add_reference :plans, :tenant, null: false, foreign_key: true
    add_reference :plans, :store, null: true, foreign_key: true
  end
end
