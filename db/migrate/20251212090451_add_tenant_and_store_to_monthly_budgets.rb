class AddTenantAndStoreToMonthlyBudgets < ActiveRecord::Migration[8.1]
  def change
    add_reference :monthly_budgets, :tenant, null: false, foreign_key: true
    add_reference :monthly_budgets, :store, null: true, foreign_key: true
  end
end
