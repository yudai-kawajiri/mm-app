require "active_support/core_ext/integer/time"

Rails.application.configure do
  # config/application.rb の設定よりも、ここに指定した設定が優先されます。

  # ====================
  # 一般設定
  # ====================
  # コードの自動リロードを無効化（本番環境では不要）
  config.enable_reloading = false

  # 起動時にすべてのコードをプリロード（パフォーマンス向上）
  config.eager_load = true

  # 詳細なエラーレポートを無効化（セキュリティのため）
  config.consider_all_requests_local = false

  # ====================
  # SSL / セキュリティ設定
  # ====================
  # SSL終端リバースプロキシを前提とした設定
  config.assume_ssl = true

  # すべてのアクセスをHTTPSに強制（HSTS有効化、セキュアCookie）
  config.force_ssl = true

  # ヘルスチェックエンドポイント（/up）のHTTPSリダイレクトをスキップ
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # DNSリバインディング攻撃対策（Hostヘッダー検証）
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # ヘルスチェックエンドポイントの Host 検証をスキップ
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # ====================
  # キャッシング設定
  # ====================
  # ビューテンプレートのフラグメントキャッシングを有効化
  config.action_controller.perform_caching = true

  # アセットファイルのキャッシュヘッダー設定（1年間有効）
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # キャッシュストアに Solid Cache を使用（永続的なキャッシュ）
  config.cache_store = :solid_cache_store

  # CDN / アセットサーバーの設定（必要に応じて有効化）
  # config.asset_host = "http://assets.example.com"

  # ====================
  # Active Storage 設定
  # ====================
  # アップロードされたファイルをローカルファイルシステムに保存
  # 本番環境では S3 などのクラウドストレージへの変更を推奨
  config.active_storage.service = :local

  # ====================
  # ロギング設定
  # ====================
  # 標準出力（STDOUT）にログを出力（コンテナ環境対応）
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)

  # リクエストIDをログタグとして追加（リクエスト追跡が容易）
  config.log_tags = [ :request_id ]

  # ログレベルを環境変数で設定可能（デフォルトは info）
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # ヘルスチェックエンドポイント（/up）のログを出力しない
  config.silence_healthcheck_path = "/up"

  # 非推奨通知（deprecation notices）のログ出力を無効化
  config.active_support.report_deprecations = false

  # ====================
  # バックグラウンドジョブ設定
  # ====================
  # Active Job のキューアダプターに Solid Queue を使用
  config.active_job.queue_adapter = :solid_queue

  # Solid Queue の接続先データベースを指定
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # ====================
  # Action Mailer 設定
  # ====================
  # メーラーテンプレートで生成されるリンクのホスト設定
  # 実際のドメイン名に変更してください
  config.action_mailer.default_url_options = { host: "example.com" }

  # メール送信エラーを無視（必要に応じて true に変更）
  # config.action_mailer.raise_delivery_errors = false

  # SMTP設定（rails credentials:edit で管理）
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # ====================
  # 国際化設定
  # ====================
  # ロケールのフォールバック機能を有効化
  # （翻訳が見つからない場合、デフォルトロケールにフォールバック）
  config.i18n.fallbacks = true

  # ====================
  # データベース設定
  # ====================
  # マイグレーション実行後のスキーマダンプを無効化
  config.active_record.dump_schema_after_migration = false

  # ログ内でのレコード検査時に :id のみ表示（個人情報保護）
  config.active_record.attributes_for_inspect = [ :id ]
end
