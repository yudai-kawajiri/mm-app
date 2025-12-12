class AddTenantAndStoreToUnits < ActiveRecord::Migration[8.1]
  def change
    add_reference :units, :tenant, null: false, foreign_key: true
    add_reference :units, :store, null: true, foreign_key: true
  end
end
