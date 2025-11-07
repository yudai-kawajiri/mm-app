class RemoveUnnecessaryCountFieldsFromMaterials < ActiveRecord::Migration[8.1]
  def change
    remove_column :materials, :unit_count_for_product, :decimal
    remove_column :materials, :unit_count_for_order, :decimal
  end
end
