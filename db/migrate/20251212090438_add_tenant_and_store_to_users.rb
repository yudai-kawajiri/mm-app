class AddTenantAndStoreToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :tenant, null: false, foreign_key: true
    add_reference :users, :store, null: true, foreign_key: true
  end
end
