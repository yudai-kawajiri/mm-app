class AddUniqueIndexToCompaniesPhone < ActiveRecord::Migration[8.1]
  def up
    # 重複している電話番号をクリーニング
    say "重複している電話番号をクリーニング中..."

    # 重複を見つける
    duplicates = Company.select(:phone)
                       .where.not(phone: [ nil, '' ])
                       .group(:phone)
                       .having('COUNT(*) > 1')
                       .pluck(:phone)

    duplicates.each do |phone|
      say "  電話番号: #{phone} の重複を処理中..."

      # 最新のレコード以外をNULLに
      companies = Company.where(phone: phone).order(created_at: :asc)
      companies[0..-2].each do |company|
        company.update_column(:phone, nil)
        say "    ID: #{company.id} の電話番号を NULL に設定"
      end

      say "    ID: #{companies.last.id} の電話番号を保持"
    end

    # ユニークインデックスを追加
    say "ユニークインデックスを追加中..."
    add_index :companies, :phone, unique: true
    say "完了！"
  end

  def down
    remove_index :companies, :phone
  end
end
