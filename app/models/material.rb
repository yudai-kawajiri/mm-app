class Material < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  # belongs_to :user
  include UserAssociatable

  belongs_to :category, optional: false

  # unit_for_product_id カラムを参照し、Unitモデルであることを明示
  belongs_to :unit_for_product, class_name: 'Unit', optional: false

  # unit_for_order_id カラムを参照し、Unitモデルであることを明示
  belongs_to :unit_for_order, class_name: 'Unit', optional: false

  # 多対多
  has_many :product_materials, dependent: :destroy
  has_many :products, through: :product_materials, dependent: :restrict_with_error

  # 各バリデーションを設定
  validates :name, presence: true
  validates :name, uniqueness: { scope: :category_id }

  # 数値項目は必須かつ0より大きい値のみ許可（エラー回避）
  validates :unit_weight_for_product,
            presence: true,
            numericality: { greater_than: 0 }

  validates :unit_weight_for_order,
            presence: true,
            numericality: { greater_than: 0 }
end
