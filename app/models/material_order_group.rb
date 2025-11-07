class MaterialOrderGroup < ApplicationRecord
  # PaperTrailで変更履歴を記録
  has_paper_trail

  # 関連付け
  # userは履歴用（作成者記録）として残す
  belongs_to :user
  has_many :materials, foreign_key: :order_group_id, dependent: :nullify

  # バリデーション
  # システム全体で一意（user_idスコープを外す）
  validates :name, presence: true, uniqueness: true

  # スコープ
  # 全ユーザーのデータを名前順で取得
  scope :ordered_by_name, -> { order(:name) }
end
