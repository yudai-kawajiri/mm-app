# frozen_string_literal: true

# Unit
#
# 単位モデル - 材料の使用単位、発注単位、製造単位を管理
#
# 使用例:
#   Unit.create(name: "g", category: :production)
#   Unit.filter_by_category(:production)
#   Unit.search_by_name("g")
#
# 単位カテゴリー:
#   - production: 使用単位（商品製造で使う単位: g, 本など）
#   - ordering: 発注単位（発注時の単位: kg, 箱など）
#   - manufacturing: 製造単位（印刷時に表示する数え方: 枚, カン, 本, 切れなど）
class Unit < ApplicationRecord
  # 変更履歴の記録
  has_paper_trail

  # 共通機能の組み込み
  include NameSearchable
  include UserAssociatable

  # 単位のカテゴリー定義
  enum :category, { production: 0, ordering: 1, manufacturing: 2 }

  # 関連付け（この単位を参照している材料がある場合は削除を制限）
  has_many :materials_as_product_unit,
           class_name: "Material",
           foreign_key: "unit_for_product_id",
           dependent: :restrict_with_error

  has_many :materials_as_order_unit,
           class_name: "Material",
           foreign_key: "unit_for_order_id",
           dependent: :restrict_with_error

  has_many :materials_as_production_unit,
           class_name: "Material",
           foreign_key: "production_unit_id",
           dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :category }
  validates :category, presence: true

  # 名前順で取得
  scope :for_index, -> { order(name: :asc) }

  # カテゴリーで絞り込み
  #
  # @param category [String, Symbol, nil] カテゴリー名
  # @return [ActiveRecord::Relation] 絞り込み結果
  scope :filter_by_category, lambda { |category|
    where(category: category) if category.present? && Unit.categories.key?(category.to_s)
  }
end
