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
# 注意: システムは全認証ユーザーでデータを共有するため、user_idは必須ではありません
module UserAssociatable
  extend ActiveSupport::Concern

  included do
    # ユーザーへの関連付け（オプショナル）
    belongs_to :user, optional: true
  end
end
