# frozen_string_literal: true

class ApplicationRequest < ApplicationRecord
  # 招待トークンの有効期間（変更が容易なように定数化）
  EXPIRE_DAYS = 7.days

  belongs_to :company, optional: true
  belongs_to :user, optional: true

  enum :status, { pending: 0, accepted: 1 }

  validates :company_name, presence: true
  validates :company_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :admin_name, presence: true
  validates :admin_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :invitation_token, uniqueness: true, allow_nil: true

  # 電話番号のフォーマット検証（ハイフンなし10桁または11桁）
  validates :company_phone, format: {
    with: /\A\d{10,11}\z/,
    message: "は10桁または11桁の数字で入力してください（ハイフンなし）"
  }, allow_blank: true

  # 招待用トークンを発行し、送信日時を記録する
  def generate_invitation_token!
    token = SecureRandom.urlsafe_base64(32)
    update!(invitation_token: token, invitation_sent_at: Time.current)
  end

  # 承認可能な状態（未完了かつ有効期限内）か判定
  def acceptable?
    pending? && invitation_token.present? && !expired?
  end

  # 招待送信から一定期間（EXPIRE_DAYS）経過しているか判定
  def expired?
    return false if invitation_sent_at.nil?
    invitation_sent_at < EXPIRE_DAYS.ago
  end
end
