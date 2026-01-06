class AddEmailToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :email, :string
  end
end
