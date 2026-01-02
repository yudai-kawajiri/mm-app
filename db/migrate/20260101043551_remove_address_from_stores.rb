class RemoveAddressFromStores < ActiveRecord::Migration[8.1]
  def change
    remove_column :stores, :address, :text
  end
end
