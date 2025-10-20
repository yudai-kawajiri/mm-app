class RemoveOldUniqueIndexAndAddScopedIndexToUnits < ActiveRecord::Migration[8.0]
  def change
    if index_exists?(:units, :name, unique: true)
      # カラム名でインデックスを削除
      remove_index :units, :name, unique: true
    end

    # 2. nameとcategoryの組み合わせがユニークであることを強制する新しいインデックスを追加する
    add_index :units, [:name, :category], unique: true
  end
end
