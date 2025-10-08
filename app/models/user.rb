class User < ApplicationRecord
  has_many :categories, dependent: :destroy
  has_many :materials, dependent: :destroy
  has_many :products, dependent: :destroy
  # Deviseの認証モジュールを設定
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable

  # 名前（name）は登録時のみ必要
  validates :name, presence: true

  validates :name, length: { maximum: 50 }
end
