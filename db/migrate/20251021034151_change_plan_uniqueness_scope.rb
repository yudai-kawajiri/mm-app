class ChangePlanUniquenessScope < ActiveRecord::Migration[8.0]
  def change
    # 1. 既存の name のみのグローバルユニークインデックスを削除
    remove_index :plans, name: "index_plans_on_name", unique: true

    # 2. 新しい name + category_id の組み合わせでユニークインデックスを追加
    add_index :plans, [:name, :category_id], unique: true
  end
end