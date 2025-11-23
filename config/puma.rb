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

# 本番環境のワーカー数（CPU コア数に応じて調整）
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# プリロード（メモリ効率化）
preload_app!

# データベース接続の再確立
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# ワーカーシャットダウンのタイムアウト
worker_shutdown_timeout 60

# 統計情報の有効化
plugin :tmp_restart
