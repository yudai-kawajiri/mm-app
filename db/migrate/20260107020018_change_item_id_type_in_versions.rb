class ChangeItemIdTypeInVersions < ActiveRecord::Migration[8.1]
  def up

    execute "DELETE FROM versions"

    remove_column :versions, :item_id
    add_column :versions, :item_id, :uuid, null: false
    add_index :versions, [:item_type, :item_id]
  end

  def down
    remove_column :versions, :item_id
    add_column :versions, :item_id, :bigint, null: false
    add_index :versions, [:item_type, :item_id]
  end
end
