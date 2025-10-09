class Unit < ApplicationRecord
  # 名前検索スコープを組み込み
  include NameSearchable
  # Userとの関連付けを追加
  belongs_to :user
  # falseを追加したので、バリデーションも追加
  validates :name, presence: true
  validates :category, presence: true

  # 基本単位と発注単位(basic を production に修正)
  enum :category, { production: 0, ordering: 1 }

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

end
