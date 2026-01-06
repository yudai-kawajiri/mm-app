class ChangeQuantityPrecisionInProductMaterials < ActiveRecord::Migration[8.1]
  def up
    # quantity カラムを他のフィールドと同じ numeric(10,3) に変更
    change_column :product_materials, :quantity, :decimal, precision: 10, scale: 3
  end

  def down
    # ロールバック時は元の numeric（精度なし）に戻す
    change_column :product_materials, :quantity, :decimal
  end
end
