class AllowNullForConditionalFieldsInMaterials < ActiveRecord::Migration[8.1]
   def change
    # 重量ベース専用フィールド（個数ベースの時はNULL許可）
    change_column_null :materials, :unit_weight_for_order, true

    # 個数ベース専用フィールド（重量ベースの時はNULL許可）
    change_column_null :materials, :pieces_per_order_unit, true
  end
end
