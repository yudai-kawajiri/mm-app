# frozen_string_literal: true

# MaterialOrderGroup
#
# 材料発注グループモデル - 発注時にまとめて扱う材料のグループを管理
#
# 使用例:
#   MaterialOrderGroup.create(name: "マグロ類")
#   MaterialOrderGroup.search_by_name("マグロ")
#   group.materials
class Resources::MaterialOrderGroup < ApplicationRecord
  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include NameSearchable
  include UserAssociatable

  # 関連付け
  has_many :materials, class_name: 'Resources::Material', foreign_key: :order_group_id, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: true

  # 名前順で取得
  scope :ordered_by_name, -> { order(:name) }

  # インデックス表示用（N+1問題対策）
  scope :for_index, -> { includes(:materials).order(:name) }
end
