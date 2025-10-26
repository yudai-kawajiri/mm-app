class RenameProductPlansToPlanProducts < ActiveRecord::Migration[8.0]
  def change
    rename_table :product_plans, :plan_products
  end
end
