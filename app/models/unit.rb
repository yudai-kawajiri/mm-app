class Unit < ApplicationRecord
# falseを追加したので、バリデーションも追加
  validates :name, presence: true
  validates :category, presence: true

  # 基本単位と発注単位
  enum category: { basic: 0, ordering: 1 }

end
