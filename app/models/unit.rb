class Unit < ApplicationRecord
  # PaperTrailで変更履歴を記録
  has_paper_trail

  # 名前検索スコープを組み込み
  include NameSearchable
  include UserAssociatable

  # この単位を参照している原材料がある場合、エラーメッセージをUnitオブジェクトに追加する
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

  # falseを追加したので、バリデーションも追加
  validates :name, presence: true
  validates :category, presence: true
  validates :name,
            uniqueness: {
              scope: :category
            }

  # 名前順
  scope :for_index, -> { order(name: :asc) }

  # 単位のカテゴリー
  # production: 使用単位（商品製造で使う単位: g, 本, など）
  # ordering: 発注単位（発注時の単位: kg, 箱, など）
  # manufacturing: 製造単位（印刷時に表示する数え方: 枚, カン, 本, 切れ, など）
  enum :category, { production: 0, ordering: 1, manufacturing: 2 }

  # categoryで絞り込むためのスコープ
  scope :filter_by_category, ->(category) do
    # category が存在し、かつ enum の有効なキーであれば絞り込む
    where(category: category) if category.present? && Unit.categories.keys.include?(category.to_s)
  end
end
