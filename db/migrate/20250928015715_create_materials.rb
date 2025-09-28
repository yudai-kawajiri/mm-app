class CreateMaterials < ActiveRecord::Migration[8.0]
  def change
    create_table :materials do |t|
      t.string :name
      t.string :unit_for_product
      t.decimal :unit_weight_for_product, precision: 10, scale: 3, null: false # 精度を指定
      t.string :unit_for_order
      t.decimal :unit_weight_for_order, precision: 10, scale: 3, null: false # 精度を指定
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
