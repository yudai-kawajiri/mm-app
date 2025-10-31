class CreateProductPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :product_plans do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.integer :puroduction_count, null: false # 製造数

      t.timestamps
    end

    # ユニークインデックスを追加
    add_index :product_plans, [ :plan_id, :product_id ], unique: true
  end
end
