class RemoveBasicUnitIdFromMaterials < ActiveRecord::Migration[8.0]
  def change
    remove_column :materials, :basic_unit_id, :integer
  end
end
