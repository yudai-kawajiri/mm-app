class AddTenantToProductMaterials < ActiveRecord::Migration[8.1]
  def change
    add_reference :product_materials, :tenant, null: false, foreign_key: true
  end
end
