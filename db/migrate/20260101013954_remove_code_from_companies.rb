class RemoveCodeFromCompanies < ActiveRecord::Migration[8.1]
  def up
    # インデックスを削除
    remove_index :companies, :code if index_exists?(:companies, :code)

    # カラムを削除
    remove_column :companies, :code
  end

  def down
    # ロールバック用：カラムを再追加
    add_column :companies, :code, :string, null: false
    add_index :companies, :code, unique: true
  end
end
