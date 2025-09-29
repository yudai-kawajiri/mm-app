class ChangeCategoryTypeToIntegerInCategories < ActiveRecord::Migration[8.0]
  def change
    # カラムの型をstringからintegerに変更する
    change_column :categories, :category_type, :integer, using: 'category_type::integer', default: 0
    # usingオプションはPostgreSQLでデータ型を安全に変換するために必要
    # すでにデータが入っている場合は、default: 0 は不要かもしれませんが
    # null: falseでデフォルト値がないとエラーになるため、
    # 'category_type'カラムのnull: false設定を活かすためにも、default: 0 を設定
  end
end
