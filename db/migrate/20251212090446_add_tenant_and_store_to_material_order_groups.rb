class AddTenantAndStoreToMaterialOrderGroups < ActiveRecord::Migration[8.1]
  def change
    add_reference :material_order_groups, :tenant, null: false, foreign_key: true
    add_reference :material_order_groups, :store, null: true, foreign_key: true
  end
end
