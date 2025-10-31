class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false         # 必須
      t.string :category_type, null: false # 必須
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # ユーザーIDと名前の組み合わせでユニークインデックスを追加
    add_index :categories, [ :user_id, :name ], unique: true
  end
end
