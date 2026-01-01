# db/migrate/YYYYMMDDHHMMSS_change_phone_unique_index_on_companies.rb

class ChangePhoneUniqueIndexOnCompanies < ActiveRecord::Migration[8.1]
  def up
    # 既存の unique インデックスを削除
    remove_index :companies, :phone if index_exists?(:companies, :phone)

    # phone が NULL でない場合のみ unique を保証する部分インデックスを追加
    add_index :companies, :phone, unique: true, where: "phone IS NOT NULL AND phone != ''"
  end

  def down
    # ロールバック用：元の unique インデックスに戻す
    remove_index :companies, :phone if index_exists?(:companies, :phone)
    add_index :companies, :phone, unique: true
  end
end
