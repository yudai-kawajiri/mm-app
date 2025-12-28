# frozen_string_literal: true

# ユーザー関連付け（user_id は optional）
module UserAssociatable
  extend ActiveSupport::Concern

  included do
    belongs_to :user, optional: true
  end
end
