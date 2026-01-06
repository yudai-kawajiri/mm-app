class RenamePuroductionCountToProductionCountInProductPlans < ActiveRecord::Migration[8.0]
  def change
    rename_column :product_plans, :puroduction_count, :production_count
  end
end
