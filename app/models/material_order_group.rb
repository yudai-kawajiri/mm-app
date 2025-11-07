class MaterialOrderGroup < ApplicationRecord
  # PaperTrailで変更履歴を記録
  has_paper_trail

  # 名前検索スコープを組み込み（Unitと同じ）
  include NameSearchable

  # 関連付け
  belongs_to :user
  has_many :materials, foreign_key: :order_group_id, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: true

  # スコープ
  scope :ordered_by_name, -> { order(:name) }

  # インデックス表示用のスコープ（N+1問題対策）
  scope :for_index, -> { includes(:materials, :user).order(:name) }
end

