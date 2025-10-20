class Unit < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  # Userとの関連付けを追加
  belongs_to :user

  # この単位を参照している原材料がある場合、エラーメッセージをUnitオブジェクトに追加する
  has_many :materials_as_product_unit,
            class_name: 'Material',
            foreign_key: 'unit_for_product_id'

  has_many :materials_as_order_unit,
            class_name: 'Material',
            foreign_key: 'unit_for_order_id'

  # falseを追加したので、バリデーションも追加
  validates :name, presence: true
  validates :category, presence: true
  validates :name,
            uniqueness: {
              scope: :category,
              message: "は、同じ単位分類では既に登録されています" # 未
            }

  # 基本単位と発注単位(basic を production に修正)
  enum :category, { production: 0, ordering: 1 }

  before_destroy :check_for_associated_materials

  # categoryで絞り込むためのスコープ
  scope :filter_by_category, ->(category) do
    # category が存在し、かつ enum の有効なキーであれば絞り込む
    where(category: category) if category.present? && Unit.categories.keys.include?(category.to_s)
  end


  # sメソッドを呼び出しているインスタンスを翻訳
  def category_i18n
    return '' if category.blank? # 未入力は空文字で対応
    I18n.t("activerecord.enums.unit.category.#{category}")
  end

  # 検索ロジックの統合メソッド
  # 検索パラメーター全体を受け取り、複数のフィルタリングを一括で適用する
  def self.search_and_filter(params)
    results = all

    # NameSearchable モジュールに定義されたスコープを利用
    results = results.search_by_name(params[:q]) if params[:q].present?

    # Unitモデルに定義された filter_by_category スコープを利用
    results = results.filter_by_category(params[:category]) if params[:category].present?

    results
  end

  # 関連リソースが存在する場合、削除をブロックする
  def check_for_associated_materials
    # 製品単位として使われているかチェック
    if materials_as_product_unit.exists?
      errors.add(:base, "この単位は製品の単位として原材料に使われているため削除できません。")
      throw :abort
    end
  end
end
