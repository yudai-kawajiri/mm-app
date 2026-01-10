class AddPortfolioDemoToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :portfolio_demo, :boolean, default: false, null: false
    add_index :companies, :portfolio_demo
  end
end
