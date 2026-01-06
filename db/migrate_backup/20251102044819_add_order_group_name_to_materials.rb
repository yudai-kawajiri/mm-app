class AddOrderGroupNameToMaterials < ActiveRecord::Migration[8.1]
  def change
    add_column :materials, :order_group_name, :string
  end
end
