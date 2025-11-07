class Material < ApplicationRecord
  # PaperTrailで変更履歴を記録
  has_paper_trail

  # 名前検索スコープを組み込み
  include NameSearchable
  include UserAssociatable

  belongs_to :category

  # unit_for_product_id カラムを参照し、Unitモデルであることを明示
  belongs_to :unit_for_product, class_name: "Unit"

  # unit_for_order_id カラムを参照し、Unitモデルであることを明示
  belongs_to :unit_for_order, class_name: "Unit"

  # 発注グループへの参照（オプショナル）
  belongs_to :order_group, class_name: "MaterialOrderGroup", optional: true

  # 仮想属性（フォームからの一時的なパラメータ）
  attr_accessor :new_order_group_name

  # 新規グループ名が入力された場合、保存前にグループを作成
  before_validation :create_order_group_from_name, if: -> { new_order_group_name.present? }
  # 多対多
  has_many :product_materials, dependent: :destroy
  has_many :products, through: :product_materials, dependent: :restrict_with_error

  # 計測方法のバリデーション
  validates :measurement_type, presence: true, inclusion: { in: %w[weight count] }

  # 各バリデーションを設定
  validates :name, presence: true
  validates :name, uniqueness: { scope: :category_id }

  # 重量ベースの場合のバリデーション
  validates :unit_weight_for_order,
            presence: true,
            numericality: { greater_than: 0 },
            if: :weight_based?

  validates :default_unit_weight,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true,
            if: :weight_based?

  # 個数ベースの場合のバリデーション（既存のpieces_per_order_unitを使用）
  validates :pieces_per_order_unit,
            presence: true,
            numericality: { greater_than: 0, only_integer: true },
            if: :count_based?

  # インデックス表示用のスコープ (N+1問題対策と並び替え)
  scope :for_index, -> { includes(:category, :unit_for_product, :unit_for_order).order(created_at: :desc) }

  # 表示順でソート（display_orderが同じ場合はid順）
  scope :ordered, -> { order(:display_order, :id) }

  def self.update_display_orders(material_ids)
    material_ids.each_with_index do |material_id, index|
      Material.where(id: material_id).update_all(display_order: index + 1)
    end
  end

  # 計測方法の判定メソッド
  def weight_based?
    measurement_type == 'weight'
  end

  def count_based?
    measurement_type == 'count'
  end

  # 発注単位の換算タイプを判定（後方互換性のため残す）
  def order_conversion_type
    return :weight if weight_based?
    return :count if count_based?

    if pieces_per_order_unit.present? && pieces_per_order_unit > 0
      :pieces
    elsif unit_weight_for_order.to_f > 0
      :weight
    else
      :none
    end
  end

  def order_group_name
    order_group&.name
  end

  private

  # 新規グループ名から発注グループを作成または取得
  def create_order_group_from_name
    return if new_order_group_name.blank?

    # 既存のグループを検索（全ユーザー共有、同じ名前があれば再利用）
    group = MaterialOrderGroup.find_or_create_by(name: new_order_group_name) do |g|
      g.user = user # 新規作成時のみuser設定（履歴用）
    end
  self.order_group_id = group.id
  end
end