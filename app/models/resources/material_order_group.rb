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
  belongs_to :company
  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include NameSearchable
  include UserAssociatable
  include Copyable
  include HasReading

  # 関連付け
  has_many :materials, class_name: "Resources::Material", foreign_key: :order_group_id, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :store_id }
  validates :reading, presence: true, uniqueness: { scope: :store_id }

  # セレクトボックス用：名前順
  scope :ordered, -> { order(:name) }

  # 一覧画面用：登録順（新しい順）
  scope :for_index, -> { order(created_at: :desc) }

  # Copyable設定
  copyable_config(
    uniqueness_scope: [ :category, :store_id ],
    uniqueness_check_attributes: [ :name ]
  )
end
