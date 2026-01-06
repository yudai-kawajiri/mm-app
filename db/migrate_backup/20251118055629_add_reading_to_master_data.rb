# db/migrate/20251118055629_add_reading_to_master_data.rb
class AddReadingToMasterData < ActiveRecord::Migration[8.1]
  def change
    # マスターデータテーブル（3つ）
    add_column :categories, :reading, :string, if_not_exists: true
    add_index :categories, :reading, if_not_exists: true

    add_column :units, :reading, :string, if_not_exists: true
    add_index :units, :reading, if_not_exists: true

    add_column :material_order_groups, :reading, :string, if_not_exists: true
    add_index :material_order_groups, :reading, if_not_exists: true

    # リソーステーブル（3つ）
    add_column :materials, :reading, :string, if_not_exists: true
    add_index :materials, :reading, if_not_exists: true

    add_column :products, :reading, :string, if_not_exists: true
    add_index :products, :reading, if_not_exists: true

    add_column :plans, :reading, :string, if_not_exists: true
    add_index :plans, :reading, if_not_exists: true
  end
end
