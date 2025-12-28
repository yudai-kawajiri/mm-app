# frozen_string_literal: true

# ステータス変更制限（使用中のリソースは変更不可）
module StatusChangeable
  extend ActiveSupport::Concern

  RESTRICTED_STATUSES = %i[draft discontinued].freeze

  class_methods do
    def restrict_status_change_if_used_in(association_name,
                                          foreign_key: :product_id,
                                          class_name: nil,
                                          statuses_to_check: RESTRICTED_STATUSES)
      validate :cannot_change_status_if_used, on: :update

      target_class_name = class_name
      target_foreign_key = foreign_key
      target_statuses = statuses_to_check

      define_method :cannot_change_status_if_used do
        return unless should_check_status_change?(target_statuses)

        association_class = resolve_association_class(target_class_name, association_name)
        return unless association_class

        if used_in_association?(association_class, target_foreign_key)
          add_status_change_error
        end
      end

      define_method :should_check_status_change? do |target_statuses|
        status_changed? &&
        !status_allows_change? &&
        target_statuses.map(&:to_s).include?(status)
      end

      define_method :status_allows_change? do
        (respond_to?(:selling?) && selling?) ||
        (respond_to?(:active?) && active?)
      end

      define_method :resolve_association_class do |class_name, association_name|
        class_name.presence&.constantize || association_name.to_s.classify.constantize
      rescue NameError => e
        Rails.logger.error "StatusChangeable: Class not found - #{e.message}"
        nil
      end

      define_method :used_in_association? do |association_class, foreign_key|
        association_class.exists?(foreign_key => id)
      end

      define_method :add_status_change_error do
        errors.add(:status, I18n.t("errors.messages.status_used_in_plans"))
      end
    end
  end
end
