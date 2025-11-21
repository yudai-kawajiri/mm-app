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
    validates :reading, uniqueness: { scope: :category_type }, if: -> { respond_to?(:category_type) }
    validates :reading, uniqueness: { scope: :category_id }, if: -> { respond_to?(:category_id) }
  end
end
