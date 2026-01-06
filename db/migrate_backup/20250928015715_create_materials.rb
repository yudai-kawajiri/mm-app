class CreateMaterials < ActiveRecord::Migration[8.0]
  def change
    create_table :materials do |t|
      t.string :name, null: false  # 必須
      t.string :unit_for_product, null: false # 必須
      t.decimal :unit_weight_for_product, precision: 10, scale: 3, null: false # 精度を指定
      t.string :unit_for_order, null: false # 必須
      t.decimal :unit_weight_for_order, precision: 10, scale: 3, null: false # 精度を指定
      t.references :user, null: false, foreign_key: true # 必須
      t.references :category, null: false, foreign_key: true # 必須

      t.timestamps
    end
  end
end
