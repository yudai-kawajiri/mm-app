class Unit < ApplicationRecord
  # Userとの関連付けを追加
  belongs_to :user
  # falseを追加したので、バリデーションも追加
  validates :name, presence: true
  validates :category, presence: true

  # 基本単位と発注単位(basic を production に修正)
  enum :category, { production: 0, ordering: 1 }

end
