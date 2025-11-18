class AddReadingToMasterData < ActiveRecord::Migration[8.1]
  def change
    # マスターデータ
    add_column :resources_categories, :reading, :string
    add_column :resources_units, :reading, :string
    add_column :resources_material_order_groups, :reading, :string

    # トランザクションデータ
    add_column :resources_materials, :reading, :string
    add_column :resources_products, :reading, :string
    add_column :resources_plans, :reading, :string

    # インデックスを追加（ソートパフォーマンス向上）
    add_index :resources_categories, :reading
    add_index :resources_units, :reading
    add_index :resources_material_order_groups, :reading
    add_index :resources_materials, :reading
    add_index :resources_products, :reading
    add_index :resources_plans, :reading
  end
end
