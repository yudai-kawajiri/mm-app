if Rails.env.production? && ENV['RUN_SEEDS'] == '1'
  Rails.application.config.after_initialize do
    begin
      puts "=========================================="
      puts "マイグレーションを実行中..."
      puts "=========================================="
      ActiveRecord::Migration.maintain_test_schema!
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
      puts "マイグレーション完了"

      puts "=========================================="
      puts "シード処理を開始します..."
      puts "=========================================="
      load Rails.root.join('db', 'seeds.rb')
      puts "シード処理完了"
    rescue => e
      puts "エラー: #{e.message}"
    end
  end
end
