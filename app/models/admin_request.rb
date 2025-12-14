# frozen_string_literal: true

# AdminRequest
#
# 管理者承認リクエストモデル
# 店舗管理者昇格、ユーザー登録などの承認フローを管理
class AdminRequest < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  belongs_to :store, optional: true
  belongs_to :approved_by, class_name: 'User', optional: true

  enum :request_type, {
    store_admin_request: 0,
    user_registration: 1
  }

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2
  }

  validates :request_type, presence: true
  validates :status, presence: true
  validates :user, presence: true
  validates :store, presence: true, if: :store_admin_request?
  validates :rejection_reason, presence: true, if: :rejected?

  scope :for_tenant, ->(tenant) { where(tenant: tenant) }
  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  def approve!(approved_by_user)
    transaction do
      update!(
        status: :approved,
        approved_by: approved_by_user,
        approved_at: Time.current
      )

      case request_type
      when 'store_admin_request'
        user.update!(role: :store_admin)
      when 'user_registration'
        user.update!(approved: true)
      end

      ApplicationRequestMailer.approval_notification(self).deliver_later
    end
  end

  def reject!(rejected_by_user, reason:)
    update!(
      status: :rejected,
      approved_by: rejected_by_user,
      approved_at: Time.current,
      rejection_reason: reason
    )

    ApplicationRequestMailer.rejection_notification(self).deliver_later
  end

  def can_be_approved?
    pending?
  end
end
