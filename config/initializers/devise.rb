# frozen_string_literal: true

# Deviseの設定ブロック
Devise.setup do |config|
  # Deviseの暗号化などに使われるシークレットキー。
  # Railsのsecret_key_baseがデフォルトで使われるため、通常は設定不要。
  # config.secret_key = '...'

  # --- Mailer Configuration (メール設定) ---

  # Devise::Mailerの送信元アドレス。パスワードリセットメールなどに使用される。
  # 【必須変更】本番環境に合わせて必ず変更してください。
  config.mailer_sender = 'info@your-app-domain.com' # 例として変更

  # config.mailer = 'Devise::Mailer' # Deviseのメール送信クラス（デフォルトのまま）

  # --- ORM configuration (O/Rマッピング設定) ---

  # Active Recordを使用することを明示（Rails標準）
  require 'devise/orm/active_record'

  # --- Authentication Configuration (認証全般設定) ---

  # 認証に使用するキー。デフォルトは[:email]。（変更不要）
  # config.authentication_keys = [:email]

  # 認証時に大文字小文字を区別しないキー。デフォルトは[:email]。（変更不要）
  config.case_insensitive_keys = [:email]

  # 認証時に前後の空白を削除するキー。デフォルトは[:email]。（変更不要）
  config.strip_whitespace_keys = [:email]

  # 複数の認証パス（セッション）からストレージへの保存をスキップする戦略
  config.skip_session_storage = [:http_auth]

  # --- Database Authenticatable (パスワード設定) ---

  # パスワードのハッシュ化のストレッチ回数。
  # テスト環境では高速化のため1、その他（開発/本番）ではセキュリティのため12。（変更不要）
  config.stretches = Rails.env.test? ? 1 : 12

  # --- Confirmable (メール認証設定) ---

  # アカウント作成後のメールアドレス変更時にも再確認を要求する。（セキュリティのためtrueを維持）
  config.reconfirmable = true

  # --- Rememberable (ログイン状態の保持) ---

  # ユーザーがサインアウトした際に、全てのRemember Meトークンを無効にする。（セキュリティのためtrueを維持）
  config.expire_all_remember_me_on_sign_out = true

  # --- Validatable (バリデーション設定) ---

  # パスワードの長さの範囲。（[6, 128]を維持）
  config.password_length = 6..128

  # メールアドレスの形式を検証するための正規表現。（デフォルトを維持）
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # --- Recoverable (パスワードリセット) ---

  # パスワードリセット用トークンの有効期間。（6時間に設定）
  config.reset_password_within = 6.hours

  # --- Navigation Configuration (ナビゲーション設定) ---

  # ログアウトに使用するHTTPメソッド。デフォルトは:delete。（変更不要）
  config.sign_out_via = :delete

  # --- Hotwire/Turbo configuration (Turbo対応) ---

  # Turbo対応のため、エラーレスポンスのステータスコードを422に設定。（変更不要）
  config.responder.error_status = :unprocessable_entity

  # Turbo対応のため、リダイレクトのステータスコードを303に設定。（変更不要）
  config.responder.redirect_status = :see_other
end
