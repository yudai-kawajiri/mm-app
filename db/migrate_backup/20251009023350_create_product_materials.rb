class CreateProductMaterials < ActiveRecord::Migration[8.0]
  def change
    create_table :product_materials do |t|
      t.references :product, null: false, foreign_key: true
      t.references :material, null: false, foreign_key: true
      t.decimal :quantity, null: false # null: false を追加

      t.timestamps
    end
  end
end
