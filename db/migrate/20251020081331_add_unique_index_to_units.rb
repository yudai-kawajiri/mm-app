class AddUniqueIndexToUnits < ActiveRecord::Migration[8.0]
  def change
    # インデックスを追加
    add_index :units, [:name, :category], unique: true
  end
end
