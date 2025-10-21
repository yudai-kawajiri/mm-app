class Material < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  # belongs_to :user
  include UserAssociatable

  belongs_to :category

  # unit_for_product_id カラムを参照し、Unitモデルであることを明示
  belongs_to :unit_for_product, class_name: 'Unit'

  # unit_for_order_id カラムを参照し、Unitモデルであることを明示
  belongs_to :unit_for_order, class_name: 'Unit'

  # 多対多
  has_many :product_materials, dependent: :destroy
  has_many :products, through: :product_materials, dependent: :restrict_with_error

  # 各バリデーションを設定
  validates :category_id, presence: true
  validates :name, presence: true

  # 関連オブジェクトではなく外部キーIDに対するバリデーションに変更
  validates :unit_for_product_id, presence: true
  validates :unit_for_order_id, presence: true

  # 数値項目は必須かつ0より大きい値のみ許可（エラー回避）
  validates :unit_weight_for_product,
            presence: true,
            numericality: { greater_than: 0 }

  validates :unit_weight_for_order,
            presence: true,
            numericality: { greater_than: 0 }

  # 検索ロジックの統合メソッド
  # 検索パラメーター全体を受け取り、複数のフィルタリングを一括で適用する
  def self.search_and_filter(params)
    results = all

    # NameSearchable モジュールに定義されたスコープを利用
    results = results.search_by_name(params[:q]) if params[:q].present?
    results = results.filter_by_category_id(params[:category_id]) if params[:category_id].present?

    results
  end

  # Categoryの名前を表示
  # 未 本当にいるのか？
  def category_name_for_display
    # 関連付けられた Category が存在すれば name 属性を返し、なければ空文字列を返す
    category.present? ? category.name : ''
  end

  # 製品単位の名前を表示するためのメソッド
  # 未 本当にいるのか？
  def unit_for_product_name
    unit_for_product.present? ? unit_for_product.name : ''
  end


  # 発注単位の名前を表示するためのメソッド
  # 未 本当にいるのか？
  def unit_for_order_name
    unit_for_order.present? ? unit_for_order.name : ''
  end
end
