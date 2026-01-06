class ChangeProductionCountToIntegerInPlanProducts < ActiveRecord::Migration[8.1]
  def change
    change_column :plan_products, :production_count, :integer, null: false
  end
end
