class RemoveAddressFromCompanies < ActiveRecord::Migration[8.1]
  def change
    remove_column :companies, :address, :string
  end
end
