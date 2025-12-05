# frozen_string_literal: true

# StatusChangeable
#
# ステータス変更制限機能を提供するConcern
#
# 使用例:
#   class Resources::Product < ApplicationRecord
#     include StatusChangeable
#     restrict_status_change_if_used_in :plan_products, foreign_key: :product_id
#   end
module StatusChangeable
  extend ActiveSupport::Concern

  class_methods do
    # ステータス変更を制限
    #
    # @param association_name [Symbol] チェック対象の関連名（例: :plan_products）
    # @param foreign_key [Symbol] 外部キー名（デフォルト: :product_id）
    # @param statuses_to_check [Array<Symbol>] チェック対象のステータス（デフォルト: [:draft, :discontinued]）
    def restrict_status_change_if_used_in(association_name, foreign_key: :product_id, statuses_to_check: [:draft, :discontinued])
      validate :cannot_change_status_if_used, on: :update

      define_method :cannot_change_status_if_used do
        return unless status_changed?
        return if selling? # 販売中への変更は許可

        # ステータスが draft または discontinued に変更される場合のみチェック
        return unless statuses_to_check.map(&:to_s).include?(status)

        association_class = association_name.to_s.classify.constantize
        if association_class.exists?(foreign_key => id)
          errors.add(:status, I18n.t("activerecord.errors.models.#{self.class.model_name.i18n_key}.attributes.status.used_in_plans"))
        end
      end
    end
  end
end
