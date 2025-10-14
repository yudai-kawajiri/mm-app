class RemovePlanDateFromPlans < ActiveRecord::Migration[8.0]
  def change
    remove_column :plans, :plan_date, :date
  end
end
