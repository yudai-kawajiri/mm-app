require "active_support/core_ext/integer/time"

Rails.application.configure do
  # コードの自動リロードを無効化（本番環境）
  config.enable_reloading = false

  # 起動時にすべてのコードをプリロード
  config.eager_load = true

  # エラー詳細を表示しない（セキュリティ）
  config.consider_all_requests_local = false

  # SSL終端リバースプロキシを前提
  config.assume_ssl = false

  # HTTPSを強制（HSTS、セキュアCookie有効化）
  config.force_ssl = true

  # DNSリバインディング攻撃対策
  allowed_hosts = ENV.fetch("ALLOWED_HOSTS", "").split(",").map(&:strip)
  config.hosts = allowed_hosts if allowed_hosts.any?

  # キャッシュを有効化
  config.action_controller.perform_caching = true

  # アセットファイルのキャッシュ（1年）
  config.public_file_server.headers = {
    "cache-control" => "public, max-age=#{1.year.to_i}"
  }

  # 静的ファイルの配信を有効化（環境変数で制御）
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # ファイルストレージ（本番環境ではS3推奨）
  config.active_storage.service = :local

  # 標準出力にログを出力（コンテナ対応）
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info").to_sym

  # ヘルスチェックのログを抑制
  config.silence_healthcheck_path = "/up" if respond_to?(:silence_healthcheck_path)

  # 非推奨警告を無効化
  config.active_support.report_deprecations = false

  # メール設定
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "localhost:3000")
  }

    # SMTP設定（SendGrid）
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.smtp_settings = {
      address: 'smtp.sendgrid.net',
      port: 587,
      domain: ENV['SENDGRID_DOMAIN'] || 'mm-app-gpih.onrender.com',
      user_name: 'apikey',
      password: ENV['SENDGRID_API_KEY'],
      authentication: :plain,
      enable_starttls_auto: true
    }

  # ロケールのフォールバック
  config.i18n.fallbacks = true

  # マイグレーション後のスキーマダンプを無効化
  config.active_record.dump_schema_after_migration = false

  # セキュリティヘッダー
  config.action_dispatch.default_headers = {
    "X-Frame-Options" => "SAMEORIGIN",
    "X-XSS-Protection" => "1; mode=block",
    "X-Content-Type-Options" => "nosniff"
  }

  # CSRF protection
  config.action_controller.default_protect_from_forgery = true
end