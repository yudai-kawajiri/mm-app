# frozen_string_literal: true

class Contact
  include ActiveModel::Model
  include ActiveModel::Attributes

  NAME_MAX_LENGTH = 100
  SUBJECT_MAX_LENGTH = 200
  MESSAGE_MAX_LENGTH = 5000
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  attribute :name
  attribute :email
  attribute :subject
  attribute :message
  attribute :honeypot

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :email, presence: true, format: { with: EMAIL_REGEX }
  validates :subject, presence: true, length: { maximum: SUBJECT_MAX_LENGTH }
  validates :message, presence: true, length: { maximum: MESSAGE_MAX_LENGTH }
  validates :honeypot, absence: true

  def deliver
    return false unless valid?

    ContactMailer.inquiry(self).deliver_now
    true
  end
end
