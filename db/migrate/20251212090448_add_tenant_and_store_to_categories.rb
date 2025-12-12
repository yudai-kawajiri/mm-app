class AddTenantAndStoreToCategories < ActiveRecord::Migration[8.1]
  def change
    add_reference :categories, :tenant, null: false, foreign_key: true
    add_reference :categories, :store, null: true, foreign_key: true
  end
end
