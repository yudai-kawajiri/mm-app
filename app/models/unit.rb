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

  # falseを追加したので、バリデーションも追加
  validates :name, presence: true
  validates :category, presence: true
  validates :name,
            uniqueness: {
              scope: :category
            }

  # 名前順
  scope :for_index, -> { order(name: :asc) }

  # 基本単位と発注単位(basic を production に修正)
  enum :category, { production: 0, ordering: 1 }

  # categoryで絞り込むためのスコープ
  scope :filter_by_category, ->(category) do
    # category が存在し、かつ enum の有効なキーであれば絞り込む
    where(category: category) if category.present? && Unit.categories.keys.include?(category.to_s)
  end
end
