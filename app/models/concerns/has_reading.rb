# app/models/concerns/has_reading.rb
module HasReading
  extend ActiveSupport::Concern

  included do
    validates :reading,
              format: {
                with: /\A[ぁ-んー]*\z/,
                message: :hiragana_only
              },
              allow_blank: true
  end
end
