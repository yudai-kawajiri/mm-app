class RemoveTotalAmountFromPlans < ActiveRecord::Migration[8.0]
  def change
    remove_column :plans, :total_amount, :integer
  end
end
