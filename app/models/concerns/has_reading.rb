# frozen_string_literal: true

# 読み仮名バリデーション（平仮名のみ、空白なし）
module HasReading
  extend ActiveSupport::Concern

  included do
    validates :reading, presence: true, format: {
      with: /\A[ぁ-ん]+\z/,
      message: :hiragana_only
    }
  end
end
