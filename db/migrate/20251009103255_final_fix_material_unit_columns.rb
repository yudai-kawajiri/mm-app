class FinalFixMaterialUnitColumns < ActiveRecord::Migration[8.0]
  def change
    # 衝突の原因となっている、NULL許容の 'unit_for_order_id' を削除
    remove_column :materials, :unit_for_order_id, :bigint

    # NOT NULL制約を持つ 'ordering_unit_id' を 'unit_for_order_id' にリネーム
    rename_column :materials, :ordering_unit_id, :unit_for_order_id

    # 'unit_for_product_id' に NOT NULL制約を追加
    change_column_null :materials, :unit_for_product_id, false

  end
end