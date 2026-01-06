class AddStoreIdToVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :versions, :store_id, :bigint
    add_index :versions, :store_id
    add_foreign_key :versions, :stores
  end
end
