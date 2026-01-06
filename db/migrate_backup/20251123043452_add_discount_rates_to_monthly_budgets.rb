class AddDiscountRatesToMonthlyBudgets < ActiveRecord::Migration[8.1]
  def change
    add_column :monthly_budgets, :forecast_discount_rate, :decimal, precision: 5, scale: 2, default: 0.0, null: false, comment: '予測見切率（%）'
    add_column :monthly_budgets, :target_discount_rate, :decimal, precision: 5, scale: 2, default: 0.0, null: false, comment: '目標見切率（%）'
  end
end
