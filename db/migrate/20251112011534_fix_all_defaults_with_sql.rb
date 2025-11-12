# SQLを直接実行してデフォルト値を削除
class FixAllDefaultsWithSql < ActiveRecord::Migration[8.1]
  def up
    # categories テーブルの category_type
    execute <<-SQL
      ALTER TABLE categories
      ALTER COLUMN category_type DROP DEFAULT,
      ALTER COLUMN category_type DROP NOT NULL;
    SQL

    # units テーブルの category
    execute <<-SQL
      ALTER TABLE units
      ALTER COLUMN category DROP DEFAULT,
      ALTER COLUMN category DROP NOT NULL;
    SQL

    # products テーブルの status
    execute <<-SQL
      ALTER TABLE products
      ALTER COLUMN status DROP DEFAULT,
      ALTER COLUMN status DROP NOT NULL;
    SQL
  end

  def down
    # ロールバック時は元の状態に戻す
    execute <<-SQL
      ALTER TABLE categories
      ALTER COLUMN category_type SET DEFAULT 0,
      ALTER COLUMN category_type SET NOT NULL;
    SQL

    execute <<-SQL
      ALTER TABLE units
      ALTER COLUMN category SET DEFAULT 0,
      ALTER COLUMN category SET NOT NULL;
    SQL

    execute <<-SQL
      ALTER TABLE products
      ALTER COLUMN status SET DEFAULT 0,
      ALTER COLUMN status SET NOT NULL;
    SQL
  end
end
