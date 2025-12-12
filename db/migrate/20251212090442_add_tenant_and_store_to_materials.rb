class AddTenantAndStoreToMaterials < ActiveRecord::Migration[8.1]
  def change
    add_reference :materials, :tenant, null: false, foreign_key: true
    add_reference :materials, :store, null: true, foreign_key: true
  end
end
