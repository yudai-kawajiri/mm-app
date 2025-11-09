# frozen_string_literal: true

# ====================================================================================
# Devise 認証設定
# ====================================================================================
# このファイルを変更した場合は、サーバーの再起動が必要です。
#
# Devise は Rails の認証ライブラリです。
# - ユーザー登録・ログイン
# - パスワードリセット
# - アカウントロック
# - メールアドレス確認
# などの機能を提供します。
#
# 参考：Devise公式ドキュメント
# https://github.com/heartcombo/devise

Devise.setup do |config|
  # ====================
  # 0. シークレットキー設定
  # ====================
  # Deviseの暗号化に使用するシークレットキー
  # Rails の secret_key_base がデフォルトで使用されるため、通常は設定不要
  # config.secret_key = '...'

  # ====================
  # 1. ORM（データベース接続）設定
  # ====================
  # Active Record を使用（Rails標準のO/Rマッパー）
  require "devise/orm/active_record"

  # ====================
  # 2. メール設定
  # ====================
  # パスワードリセットメール等の送信元アドレス
  # 【重要】本番環境では必ず実際のドメインに変更してください
  # 例：'noreply@sushi-management.com'
  config.mailer_sender = "info@your-app-domain.com"

  # Deviseのメール送信クラス（デフォルトのまま使用）
  # カスタムメーラーを使用する場合のみ変更
  # config.mailer = 'Devise::Mailer'

  # ====================
  # 3. 認証方法の設定
  # ====================
  # ログイン時に使用するキー（デフォルト：メールアドレス）
  # ユーザー名でログインする場合は [:username] に変更
  # config.authentication_keys = [:email]

  # 大文字小文字を区別しないキー
  # メールアドレスは通常区別しない（user@example.com = USER@example.com）
  config.case_insensitive_keys = [:email]

  # 前後の空白を自動削除するキー
  # ユーザーが誤って空白を入力してもログインできるようにする
  config.strip_whitespace_keys = [:email]

  # セッションストレージをスキップする認証方式
  # HTTP Basic認証などでセッションを使用しない場合の設定
  config.skip_session_storage = [:http_auth]

  # ====================
  # 4. パスワード設定
  # ====================
  # パスワードのハッシュ化のストレッチ回数
  # 回数が多いほど安全だが処理時間が増える
  # - テスト環境：1回（高速化）
  # - 開発/本番環境：12回（セキュリティ重視）
  config.stretches = Rails.env.test? ? 1 : 12

  # パスワードの長さの制限
  # 最小6文字、最大128文字
  # 【セキュリティ】最小8文字以上を推奨（現在は6文字）
  config.password_length = 6..128

  # ====================
  # 5. バリデーション設定
  # ====================
  # メールアドレスの形式を検証する正規表現
  # デフォルトは簡易的なチェック（@が含まれているか）
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ====================
  # 6. メールアドレス確認（Confirmable）
  # ====================
  # メールアドレス変更時に再確認を要求する
  # セキュリティのため true を推奨
  # - true：変更後に確認メールが送信される
  # - false：即座に変更される（セキュリティリスク）
  config.reconfirmable = true

  # ====================
  # 7. ログイン状態の保持（Rememberable）
  # ====================
  # サインアウト時に全ての「ログイン状態を保持」トークンを無効化
  # セキュリティのため true を推奨
  # 他のデバイスでログイン中でも、1箇所でログアウトすれば全て無効化
  config.expire_all_remember_me_on_sign_out = true

  # ====================
  # 8. パスワードリセット（Recoverable）
  # ====================
  # パスワードリセット用トークンの有効期間
  # 6時間に設定（デフォルトは24時間）
  # セキュリティのため短めの設定を推奨
  config.reset_password_within = 6.hours

  # ====================
  # 9. アカウントロック（Lockable）
  # ====================
  # 現在は無効化されています
  # 有効化する場合は以下を設定：
  # config.lock_strategy = :failed_attempts  # ログイン失敗回数でロック
  # config.unlock_strategy = :email          # メールでアンロック
  # config.maximum_attempts = 5              # 最大試行回数
  # config.unlock_in = 1.hour                # 自動アンロックまでの時間
  config.lock_strategy = :none
  config.unlock_strategy = :none

  # ====================
  # 10. ログアウト設定
  # ====================
  # ログアウトに使用するHTTPメソッド
  # :delete = DELETEメソッド（RESTful、CSRF保護のため推奨）
  # :get を使用する場合は CSRF攻撃のリスクあり
  config.sign_out_via = :delete

  # ====================
  # 11. Hotwire/Turbo対応
  # ====================
  # Rails 7+ の Turbo との互換性設定

  # エラー時のHTTPステータスコード
  # 422 Unprocessable Entity（Turbo推奨）
  config.responder.error_status = :unprocessable_entity

  # リダイレクト時のHTTPステータスコード
  # 303 See Other（Turbo推奨）
  config.responder.redirect_status = :see_other
end

# ====================
# 製造管理システムでの Devise 使用状況
# ====================
# 【有効化されているモジュール】
# - Database Authenticatable：パスワード認証
# - Registerable：ユーザー登録
# - Recoverable：パスワードリセット
# - Rememberable：ログイン状態の保持
# - Validatable：メールアドレス/パスワードの検証
#
# 【無効化されているモジュール】
# - Confirmable：メールアドレス確認（必要に応じて有効化）
# - Lockable：アカウントロック（現在は無効）
# - Trackable：ログイン履歴の追跡
# - Timeoutable：一定時間後の自動ログアウト
# - Omniauthable：外部サービス認証（Google, Facebook等）
#
# 【カスタマイズ】
# - Users::RegistrationsController でレイアウトを切り替え
#   - 新規登録：シンプルなレイアウト
#   - 編集：認証後のレイアウト（サイドバー付き）

# ====================
# 本番環境での推奨設定
# ====================
# 1. メール送信元の変更
#    config.mailer_sender = 'noreply@your-actual-domain.com'
#
# 2. パスワード最小文字数の引き上げ（オプション）
#    config.password_length = 8..128
#
# 3. アカウントロックの有効化（オプション）
#    config.lock_strategy = :failed_attempts
#    config.unlock_strategy = :email
#    config.maximum_attempts = 5
#
# 4. メールアドレス確認の有効化（オプション）
#    モデルに :confirmable を追加
#    マイグレーションで confirmation_token 等を追加
