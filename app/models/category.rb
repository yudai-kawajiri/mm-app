# 未 生ねたを商品で使ってるのに削除できる
class Category < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  # belongs_to :user
  include UserAssociatable

  # データベースには 0, 1, 2 が保存されるが、コードでは :material, :product, :plan で扱う
  enum :category_type, { material: 0, product: 1, plan: 2 }

  # 関連付け
  has_many :materials, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error
  has_many :plans, dependent: :restrict_with_error


  # バリデーション
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :category_type, presence: true

  private

  # 検索パラメーター全体を受け取り、複数のフィルタリングを一括で適用する
  def self.search_and_filter(params)
    results = all

    # NameSearchable モジュールに定義されたスコープを利用
    results = results.search_by_name(params[:q]) if params[:q].present?

    # NameSearchable モジュール（または Category モデル自身）に定義されたスコープを利用
    results = results.filter_by_category_type(params[:category_type]) if params[:category_type].present?

    results
  end

  # selfでメソッドを呼び出しているインスタンスのcategory_typeを翻訳
  # 未　なくても本来動く？
  def category_type_i18n
    return '' if category_type.blank? # 未入力は空文字で対応
    I18n.t("activerecord.enums.category.category_type.#{self.category_type}")
  end

end