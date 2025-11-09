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

  # カテゴリー種別の定義（データベースには0, 1, 2として保存）
  enum :category_type, { material: 0, product: 1, plan: 2 }

  # 関連付け（削除時は関連データの存在をチェック）
  has_many :materials, class_name: 'Resources::Material', dependent: :restrict_with_error
  has_many :products, class_name: 'Resources::Product', dependent: :restrict_with_error
  has_many :plans, class_name: 'Resources::Plan', dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category_type }
  validates :category_type, presence: true

  # 名前の昇順で取得
  scope :for_index, -> { order(name: :asc) }
end
