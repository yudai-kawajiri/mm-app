class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.date :plan_date, null: false # 製造計画日には値が必須
      # 外部キー制約と非NULL制約の追加(カテゴリーは明示的に記載)
      t.references :category, foreign_key: { to_table: :categories }, null: false
      t.references :user, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end
  end
end
