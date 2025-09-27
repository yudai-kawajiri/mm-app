class User < ApplicationRecord
  # Deviseの認証モジュールを設定
  # :database_authenticatable（パスワード認証）
  # :registerable（ユーザー登録・編集）
  # :recoverable（パスワードリセット）
  # :rememberable（「ログイン情報を記憶する」チェックボックス）
  # :validatable（メールアドレスとパスワードのバリデーション）
  # ※ その他、:confirmable, :lockable, :timeoutable, :trackable, :omniauthable などが必要に応じて追加可能
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable

  # 名前（name）は登録時のみ必要
  validates :name, presence: true

  validates :name, length: { maximum: 50 }
end
