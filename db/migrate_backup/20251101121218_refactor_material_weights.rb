class RefactorMaterialWeights < ActiveRecord::Migration[8.1]
  def change
    # product_materialsに商品ごとの重量を追加
    add_column :product_materials, :unit_weight, :decimal, precision: 10, scale: 3, null: false, default: 0

    # materialsから製造時の重量を削除
    remove_column :materials, :unit_weight_for_product, :decimal
  end
end
