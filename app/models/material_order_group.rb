class MaterialOrderGroup < ApplicationRecord
  # PaperTrailで変更履歴を記録
  has_paper_trail

  # 関連付け
  belongs_to :user
  has_many :materials, foreign_key: :order_group_id, dependent: :nullify

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :user_id }

  # スコープ
  # ユーザーごとの発注グループを名前順で取得
  scope :for_user, ->(user) { where(user: user).order(:name) }
  scope :ordered_by_name, -> { order(:name) }
end