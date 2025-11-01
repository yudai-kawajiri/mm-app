class Material < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  include UserAssociatable

  belongs_to :category

  # unit_for_product_id カラムを参照し、Unitモデルであることを明示
  belongs_to :unit_for_product, class_name: "Unit"

  # unit_for_order_id カラムを参照し、Unitモデルであることを明示
  belongs_to :unit_for_order, class_name: "Unit"

  # 多対多
  has_many :product_materials, dependent: :destroy
  has_many :products, through: :product_materials, dependent: :restrict_with_error

  # 各バリデーションを設定
  validates :name, presence: true
  validates :name, uniqueness: { scope: :category_id }

  validates :unit_weight_for_order,
            presence: true,
            numericality: { greater_than: 0 }

  validates :default_unit_weight,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :pieces_per_order_unit,
            numericality: { greater_than: 0, only_integer: true },
            allow_nil: true

  # インデックス表示用のスコープ (N+1問題対策と並び替え)
  scope :for_index, -> { includes(:category, :unit_for_product, :unit_for_order).order(created_at: :desc) }

  # 発注単位の換算タイプを判定
  def order_conversion_type
    if pieces_per_order_unit.present? && pieces_per_order_unit > 0
      :pieces  # 個数ベース（例: 1箱=50枚）
    elsif unit_weight_for_order > 0
      :weight  # 重量ベース（例: 1パック=1000g）
    else
      :none
    end
  end
end
