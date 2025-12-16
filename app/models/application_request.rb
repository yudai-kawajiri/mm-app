class ApplicationRequest < ApplicationRecord
  belongs_to :tenant, optional: true
  belongs_to :user, optional: true

  enum :status, { pending: 0, accepted: 1 }

  validates :company_name, presence: true
  validates :company_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :contact_name, presence: true
  validates :contact_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :invitation_token, uniqueness: true, allow_nil: true

  def generate_invitation_token!
    token = SecureRandom.urlsafe_base64(32)
    update!(invitation_token: token, invitation_sent_at: Time.current)
  end

  def acceptable?
    pending? && invitation_token.present? && !expired?
  end

  def expired?
    return false if invitation_sent_at.nil?
    invitation_sent_at < 7.days.ago
  end
end
