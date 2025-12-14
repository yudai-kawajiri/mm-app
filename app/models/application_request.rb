class ApplicationRequest < ApplicationRecord
  belongs_to :tenant, optional: true

  # ステータス: pending(登録待ち), completed(登録完了)
  enum :status, {
    pending: 0,
    completed: 1
  }

  # バリデーション
  validates :company_name, presence: true
  validates :company_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :admin_name, presence: true
  validates :admin_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :invitation_token, uniqueness: true, allow_nil: true

  # コールバック
  before_create :generate_invitation_token

  # 招待トークン生成
  def generate_invitation_token
    self.invitation_token = SecureRandom.urlsafe_base64(32)
    self.invitation_sent_at = Time.current
  end

  # 招待URL
  def invitation_url
    Rails.application.routes.url_helpers.accept_application_request_url(
      token: invitation_token,
      host: ENV.fetch('APP_HOST', 'localhost:3000'),
      protocol: ENV.fetch('APP_PROTOCOL', 'http')
    )
  end

  # 招待受諾可能か
  def acceptable?
    pending? && invitation_token.present? && !expired?
  end

  # 招待期限切れか（7日間）
  def expired?
    invitation_sent_at && invitation_sent_at < 7.days.ago
  end

  # 登録完了処理
  def complete!
    update!(status: :completed)
  end
end
