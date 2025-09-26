require "active_support/core_ext/integer/time" # 時間に関するメソッド（例: 2.days）を使うために必要

Rails.application.configure do
  # config/application.rb の設定よりも、ここに指定した設定が優先されます。

  # --- 一般設定 ---

  # コードの変更をサーバー再起動なしで即座に反映させる（開発効率向上）
  config.enable_reloading = true

  # 起動時にコードをプリロード（Eager Load）しない
  config.eager_load = false

  # エラー発生時に詳細なエラーレポートを表示する
  config.consider_all_requests_local = true

  # サーバーの処理時間計測を有効にする
  config.server_timing = true

  # --- キャッシング設定 ---

  # Action Controller のキャッシングを有効/無効にする設定
  # "tmp/caching-dev.txt" ファイルの有無で切り替わる
  if Rails.root.join("tmp/caching-dev.txt").exist?
    # ファイルが存在する場合（キャッシングが有効な場合）
    config.action_controller.perform_caching = true
    # フラグメントキャッシュのログ出力を有効にする
    config.action_controller.enable_fragment_cache_logging = true
    # 公開ファイルのキャッシュヘッダーを設定 (2日間有効)
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    # ファイルが存在しない場合（キャッシングが無効な場合）
    config.action_controller.perform_caching = false
  end

  # キャッシュストアの変更 (デフォルトでは:memory_store)
  config.cache_store = :memory_store

  # --- Active Storage 設定 ---

  # アップロードされたファイルをローカルファイルシステムに保存する設定
  config.active_storage.service = :local

  # --- Action Mailer / Devise 設定 ---

  # メーラーがメールを送信できなくてもエラーを発生させない
  config.action_mailer.raise_delivery_errors = false

  # テンプレート変更時のメーラーのキャッシングを行わない
  config.action_mailer.perform_caching = false

  # 【Devise必須設定】メーラーテンプレートで生成されるリンクのホストとポートを設定
  # （パスワードリセットなどのメール機能に必要）
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # --- ロギングとデバッグ設定 ---

  # 非推奨通知（deprecation notices）をRailsロガーに出力する
  config.active_support.deprecation = :log

  # マイグレーションが未完了の場合、ページロード時にエラーを発生させる
  config.active_record.migration_error = :page_load

  # ログ内でデータベースクエリをトリガーしたコードをハイライト表示する
  config.active_record.verbose_query_logs = true

  # ログ内のSQLクエリに実行時情報タグ（ランタイム情報）を追記する
  config.active_record.query_log_tags_enabled = true

  # ログ内でバックグラウンドジョブをエンキューしたコードをハイライト表示する
  config.active_job.verbose_enqueue_logs = true

  # --- i18n / View 設定 ---

  # 翻訳ファイルがない場合にエラーを発生させる設定（現在はコメントアウト）
  # config.i18n.raise_on_missing_translations = true

  # レンダリングされたビューにファイル名を注釈として追記する
  config.action_view.annotate_rendered_view_with_filenames = true

  # --- その他設定 ---

  # Action Cable のCSRF保護を無効にする設定（現在はコメントアウト）
  # config.action_cable.disable_request_forgery_protection = true

  # `before_action` の `only`/`except` オプションで存在しないアクションを参照した場合にエラーを発生させる
  config.action_controller.raise_on_missing_callback_actions = true

  # `bin/rails generate`で生成されたファイルにRuboCopの自動修正を適用する設定（現在はコメントアウト）
  # config.generators.apply_rubocop_autocorrect_after_generate!
end
