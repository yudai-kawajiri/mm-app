# frozen_string_literal: true

# Category
#
# カテゴリーモデル - 材料、製品、計画の分類を管理
#
# 使用例:
#   Category.create(name: "生ネタ", category_type: :material)
#   Category.material.for_index
#   Category.search_by_name("生")
#
# カテゴリー種別:
#   - material: 材料カテゴリー (0)
#   - product: 製品カテゴリー (1)
#   - plan: 計画カテゴリー (2)
class Resources::Category < ApplicationRecord
  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include NameSearchable
  include UserAssociatable
  include Copyable

  # カテゴリー種別の定義（データベースには0, 1, 2として保存）
  enum :category_type, { material: 0, product: 1, plan: 2 }

  # 関連付け（削除時は関連データの存在をチェック）
  has_many :materials, class_name: 'Resources::Material', dependent: :restrict_with_error
  has_many :products, class_name: 'Resources::Product', dependent: :restrict_with_error
  has_many :plans, class_name: 'Resources::Plan', dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_type }
  validates :category_type, presence: true

  # 一覧画面用：登録順（新しい順）
  scope :for_index, -> { order(created_at: :desc) }

  # セレクトボックス用：名前順
  scope :ordered, -> { order(:name) }

  # カテゴリータイプで絞り込み
  scope :for_materials, -> { where(category_type: :material) }
  scope :for_products, -> { where(category_type: :product) }
  scope :for_plans, -> { where(category_type: :plan) }

  # Copyable設定
  copyable_config(
    name_format: ->(original_name, copy_count) { "#{original_name} (コピー#{copy_count})" },
    uniqueness_scope: :category_type,
    uniqueness_check_attributes: [:name]
  )
end
