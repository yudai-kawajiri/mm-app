class AddMeasurementFieldsToMaterials < ActiveRecord::Migration[8.1]
  def change
    # 計測方法: weight（重量ベース）または count（個数ベース）
    add_column :materials, :measurement_type, :string, default: 'weight', null: false

    # 発注グループへの参照
    add_reference :materials, :order_group, foreign_key: { to_table: :material_order_groups }

    # 個数ベース用のカラム（既存のweight系カラムと対）
    add_column :materials, :unit_count_for_product, :decimal, precision: 10, scale: 2
    add_column :materials, :unit_count_for_order, :decimal, precision: 10, scale: 2

    add_index :materials, :measurement_type
  end
end
