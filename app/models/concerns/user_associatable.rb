module UserAssociatable
  extend ActiveSupport::Concern

  included do
    belongs_to :user, optional: false
    validates :user_id, presence: true
  end
end