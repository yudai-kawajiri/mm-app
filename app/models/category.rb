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

  # selfでメソッドを呼び出しているインスタンスのcategory_typeを翻訳
  # 未　なくても本来動く？
  def category_type_i18n
    return '' if category_type.blank? # 未入力は空文字で対応
    I18n.t("activerecord.enums.category.category_type.#{self.category_type}")
  end

end