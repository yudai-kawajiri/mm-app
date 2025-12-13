# app/models/concerns/has_reading.rb
module HasReading
  extend ActiveSupport::Concern

  included do
    validates :reading,
              presence: true,
              format: {
                with: /\A[ぁ-んー]*\z/,
                message: :hiragana_only
              }

    # モデルごとに適切なスコープを設定
  end
end
