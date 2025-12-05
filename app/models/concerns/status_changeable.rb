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
    def restrict_status_change_if_used_in(association_name, foreign_key: :product_id, class_name: nil, statuses_to_check: [:draft, :discontinued])
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
# frozen_string_literal: true

# StatusChangeable
#
# ステータス変更制限機能を提供するConcern
#
# 使用例:
#   class Resources::Product < ApplicationRecord
#     include StatusChangeable
#     restrict_status_change_if_used_in :plan_products,
#                                       foreign_key: :product_id,
#                                       class_name: 'Planning::PlanProduct'
#   end
module StatusChangeable
  extend ActiveSupport::Concern

  class_methods do
    # ステータス変更を制限
    #
    # @param association_name [Symbol] チェック対象の関連名（例: :plan_products）
    # @param foreign_key [Symbol] 外部キー名（デフォルト: :product_id）
    # @param class_name [String] チェック対象のクラス名（例: 'Planning::PlanProduct'）
    # @param statuses_to_check [Array<Symbol>] チェック対象のステータス（デフォルト: [:draft, :discontinued]）
    def restrict_status_change_if_used_in(association_name, foreign_key: :product_id, class_name: nil, statuses_to_check: [:draft, :discontinued])
      validate :cannot_change_status_if_used, on: :update

      # クロージャで変数をキャプチャ
      target_class_name = class_name
      target_foreign_key = foreign_key
      target_statuses = statuses_to_check

      define_method :cannot_change_status_if_used do
        return unless status_changed?
        return if selling? # 販売中への変更は許可

        # ステータスが draft または discontinued に変更される場合のみチェック
        return unless target_statuses.map(&:to_s).include?(status)

        # クラス名が指定されている場合はそれを使用、なければ関連名から推測
        association_class = if target_class_name.present?
          target_class_name.constantize
        else
          association_name.to_s.classify.constantize
        end

        if association_class.exists?(target_foreign_key => id)
          errors.add(:status, I18n.t("activerecord.errors.models.#{self.class.model_name.i18n_key}.attributes.status.used_in_plans"))
        end
      rescue NameError => e
        # クラスが見つからない場合はログに記録してスキップ
        Rails.logger.error "StatusChangeable: Class not found - #{e.message}"
      end
    end
  end
end
