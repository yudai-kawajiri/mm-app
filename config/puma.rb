# スレッド数の設定
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# ワーカータイムアウト（開発環境のみ）
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# ポート番号
port ENV.fetch("PORT") { 3000 }

# 環境
environment ENV.fetch("RAILS_ENV") { "development" }

# PIDファイル
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# 本番環境のワーカー数
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# プリロード
preload_app!

# before_fork: DB接続を切断
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# on_worker_boot: DB接続再確立 + 本番環境マイグレーション（1回のみ）
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)

  if ENV["RAILS_ENV"] == "production" && ENV["PUMA_WORKER_ID"] == "0"
    require "rake"
    Rails.application.load_tasks

    begin
      puts "Checking for pending migrations..."
      Rake::Task["db:migrate"].invoke
      puts "Migrations completed successfully"
    rescue => e
      puts "Migration warning: #{e.message}"
    end
  end
end

# ワーカーシャットダウンのタイムアウト
worker_timeout 60

# 統計情報の有効化
plugin :tmp_restart
