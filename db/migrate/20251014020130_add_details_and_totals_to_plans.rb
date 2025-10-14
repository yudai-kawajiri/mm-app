class AddDetailsAndTotalsToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :name, :string, null: false
    add_column :plans, :description, :text
    add_column :plans, :total_amount, :integer, null: false, default: 0
    add_column :plans, :status, :integer, null: false, default: 0
  end
end
