class Category < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  # belongs_to :user
  include UserAssociatable

  # データベースには 0, 1, 2 が保存されるが、コードでは :material, :product, :plan で扱う
  enum :category_type, { material: 0, product: 1, plan: 2 }

  # 関連付け
  has_many :materials, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error
  has_many :plans, dependent: :restrict_with_error


  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :category_type, presence: true
end