class ChangeUnitUniquenessScope < ActiveRecord::Migration[8.0]
  def change
    # 古いグローバルユニークインデックスを削除
    remove_index :units, name: "index_units_on_name", unique: true

    # 新しい name + category のユニークインデックスを追加
    add_index :units, [:name, :category], unique: true
  end
end