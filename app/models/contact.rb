# frozen_string_literal: true

# Contact
#
# お問い合わせフォームのモデル
class Contact
  include ActiveModel::Model
  include ActiveModel::Attributes

  # 文字数制限定数
  NAME_MAX_LENGTH = 100
  SUBJECT_MAX_LENGTH = 200
  MESSAGE_MAX_LENGTH = 5000

  attribute :name, :string
  attribute :email, :string
  attribute :subject, :string
  attribute :message, :string

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true, length: { maximum: SUBJECT_MAX_LENGTH }
  validates :message, presence: true, length: { maximum: MESSAGE_MAX_LENGTH }
end
