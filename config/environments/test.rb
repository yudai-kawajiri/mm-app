# テスト環境は、テストスイートを実行するためだけに使用されます。
# テストデータベースは「スクラッチスペース」であり、テスト実行ごとに
# 削除・再作成されます。データの永続性に依存しないでください。

Rails.application.configure do
  # config/application.rb の設定よりも、ここに指定した設定が優先されます。

  # ====================
  # 一般設定
  # ====================
  # ファイル監視とリロードを無効化（テスト実行には不要）
  config.enable_reloading = false

  # Eager loading の設定（CI環境では有効化推奨）
  # ローカルテスト: false（高速化）
  # CI環境: true（本番環境と同じ条件でテスト）
  config.eager_load = ENV["CI"].present?

  # すべてのリクエストをローカルとして扱う（詳細なエラー表示）
  config.consider_all_requests_local = true

  # ====================
  # キャッシング設定
  # ====================
  # キャッシュを無効化（テストごとにクリーンな状態を保証）
  config.cache_store = :null_store

  # 公開ファイルサーバーのキャッシュヘッダー（1時間）
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }

  # ====================
  # エラーハンドリング設定
  # ====================
  # レスキュー可能な例外はテンプレートを表示、その他は例外を発生
  config.action_dispatch.show_exceptions = :rescuable

  # ====================
  # セキュリティ設定
  # ====================
  # CSRF保護を無効化（テスト環境では不要）
  config.action_controller.allow_forgery_protection = false

  # `before_action` の `only`/`except` で存在しないアクションを参照した場合にエラー
  config.action_controller.raise_on_missing_callback_actions = true

  # ====================
  # Active Storage 設定
  # ====================
  # アップロードされたファイルを一時ディレクトリに保存
  # テスト実行後に自動削除される
  config.active_storage.service = :test

  # ====================
  # Action Mailer 設定
  # ====================
  # メールを実際に送信せず、配列に蓄積（ActionMailer::Base.deliveries）
  config.action_mailer.delivery_method = :test

  # メーラーテンプレートで生成されるリンクのホスト設定
  config.action_mailer.default_url_options = { host: "example.com" }

  # ====================
  # ロギングとデバッグ設定
  # ====================
  # 非推奨通知（deprecation notices）を標準エラー出力に表示
  config.active_support.deprecation = :stderr

  # ====================
  # 開発支援機能（コメントアウト）
  # ====================
  # 翻訳ファイルがない場合にエラーを発生させる（i18nテスト時に有効化）
  # config.i18n.raise_on_missing_translations = true

  # レンダリングされたビューにファイル名を注釈として追記（デバッグ時に有効化）
  # config.action_view.annotate_rendered_view_with_filenames = true
end
