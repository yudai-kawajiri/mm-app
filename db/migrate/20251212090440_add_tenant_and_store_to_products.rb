class AddTenantAndStoreToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :tenant, null: false, foreign_key: true
    add_reference :products, :store, null: true, foreign_key: true
  end
end
