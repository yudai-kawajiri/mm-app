class AddStatusToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :status, :integer
  end
end
