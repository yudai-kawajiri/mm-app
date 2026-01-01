class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :stores, dependent: :destroy
  has_many :admin_requests, dependent: :destroy
  has_many :application_requests, dependent: :destroy
  has_many :categories, class_name: "Resources::Category", dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :phone, allow_blank: true, uniqueness: { allow_nil: true }, format: { with: /\A\d{10,11}\z/, allow_blank: true }

  before_validation :generate_invitation_token, on: :create

  private

  def generate_invitation_token
    self.invitation_token ||= SecureRandom.urlsafe_base64(32)
  end
end
