class SetGlobalUniquenessOnCategory < ActiveRecord::Migration[8.0]
  def change
    # 1. 既存のユニークインデックスを削除
    remove_index :categories, name: "index_categories_on_user_id_and_name"

    # 2. 新しいグローバルユニークインデックスを追加
    add_index :categories, [ :name, :category_type ], unique: true
  end
end
