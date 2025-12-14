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
  }, prefix: true

  enum :status, {
    pending: 0,   # 承認待ち
    approved: 1,  # 承認済み
    rejected: 2   # 却下
  }, prefix: true

  validates :request_type, presence: true
  validates :status, presence: true
  validates :user, presence: true
  validates :store, presence: true, if: :store_admin_request?
  validates :rejection_reason, presence: true, if: :status_rejected?

  # Scopes
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
        # 店舗管理者リクエストの場合、ユーザーを店舗管理者に昇格
        user.update!(role: :store_admin)
      when 'user_registration'
        # ユーザー登録リクエストの場合、承認フラグを立てる
        user.update!(approved: true)
      end
    end
  end

  # 却下処理
  def reject!(rejected_by_user, reason:)
    update!(
      status: :rejected,
      approved_by: rejected_by_user,
      approved_at: Time.current,
      rejection_reason: reason
    )
  end

  # 承認可能か
  def can_be_approved?
    status_pending?
  end
end
