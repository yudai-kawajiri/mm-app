class AddProductionUnitToMaterials < ActiveRecord::Migration[8.1]
  def change
    add_column :materials, :production_unit, :string
    add_index :materials, :production_unit
  end
end
