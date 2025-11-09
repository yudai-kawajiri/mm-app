# frozen_string_literal: true

# UserAssociatable
#
# User関連付けの共通設定を提供するConcern
#
# 使用例:
#   class Plan < ApplicationRecord
#     include UserAssociatable
#   end
#
# 使用モデル: Plan, Product, Material, Daily, Unit, Category など
# ユーザーに紐づくすべてのリソースで使用
module UserAssociatable
  extend ActiveSupport::Concern

  included do
    # ユーザーへの必須関連付け
    belongs_to :user, optional: false

    # ユーザーIDの存在検証
    validates :user_id, presence: true
  end
end
