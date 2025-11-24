require "active_support/core_ext/integer/time"

Rails.application.configure do
  # config/application.rb の設定よりも、ここに指定した設定が優先されます。

  # ====================
  # 一般設定
  # ====================
  # コードの変更をサーバー再起動なしで即座に反映させる（開発効率向上）
  config.enable_reloading = true

  # 起動時にコードをプリロード（Eager Load）しない
  config.eager_load = false

  # エラー発生時に詳細なエラーレポートを表示する
  config.consider_all_requests_local = true

  # サーバーの処理時間計測を有効にする
  config.server_timing = true

  # ====================
  # URL設定（Devise / Active Storage 共通）
  # ====================
  # メーラーとコントローラーで生成されるリンクのホストとポートを設定
  # - Devise: パスワードリセットメールなどのリンク生成に必須
  # - Active Storage: 画像URL生成に必須
  default_url_options = { host: "localhost", port: 3000 }
  config.action_mailer.default_url_options = default_url_options
  config.action_controller.default_url_options = default_url_options

  # ====================
  # キャッシング設定
  # ====================
  # "tmp/caching-dev.txt" ファイルの有無でキャッシングを切り替える
  # 作成: rails dev:cache
  # 削除: rails dev:cache（再実行）
  if Rails.root.join("tmp/caching-dev.txt").exist?
    # キャッシング有効時の設定
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    # キャッシング無効時の設定
    config.action_controller.perform_caching = false
  end

  # キャッシュストアの設定（開発環境ではメモリストアを使用）
  config.cache_store = :memory_store

  # ====================
  # Active Storage 設定
  # ====================
  # アップロードされたファイルをローカルファイルシステムに保存
  config.active_storage.service = :local

  # ====================
  # Action Mailer 設定
  # ====================
  # メール送信エラーを無視（開発環境では送信失敗してもエラーにしない）
  config.action_mailer.raise_delivery_errors = true

  # テンプレート変更時のメーラーのキャッシングを行わない
  config.action_mailer.perform_caching = false

  # MailCatcher を使用してメールをキャプチャ
  # Docker環境: サービス名 "mailcatcher"、ポート 1025
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("MAILCATCHER_HOST", "localhost"),
    port: ENV.fetch("MAILCATCHER_PORT", 1025).to_i
  }

  # ====================
  # データベース設定
  # ====================
  # マイグレーションが未完了の場合、ページロード時にエラーを発生させる
  config.active_record.migration_error = :page_load

  # ログ内でデータベースクエリをトリガーしたコードをハイライト表示
  config.active_record.verbose_query_logs = true

  # ログ内のSQLクエリに実行時情報タグを追記
  config.active_record.query_log_tags_enabled = true

  # ====================
  # バックグラウンドジョブ設定
  # ====================
  # ログ内でバックグラウンドジョブをエンキューしたコードをハイライト表示
  config.active_job.verbose_enqueue_logs = true

  # ====================
  # ロギングとデバッグ設定
  # ====================
  # 非推奨通知（deprecation notices）をRailsロガーに出力
  config.active_support.deprecation = :log

  # レンダリングされたビューにファイル名を注釈として追記
  config.action_view.annotate_rendered_view_with_filenames = true

  # ====================
  # セキュリティ設定
  # ====================
  # `before_action` の `only`/`except` オプションで存在しないアクションを参照した場合にエラーを発生させる
  config.action_controller.raise_on_missing_callback_actions = true

  # ====================
  # 開発支援機能（コメントアウト）
  # ====================
  # 翻訳ファイルがない場合にエラーを発生させる（i18n開発時に有効化）
  # config.i18n.raise_on_missing_translations = true

  # Action Cable のCSRF保護を無効にする（WebSocket開発時に有効化）
  # config.action_cable.disable_request_forgery_protection = true

  # `bin/rails generate`で生成されたファイルにRuboCopの自動修正を適用
  # config.generators.apply_rubocop_autocorrect_after_generate!
end
