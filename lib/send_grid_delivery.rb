# frozen_string_literal: true

require 'sendgrid-ruby'

class SendGridDelivery
  include SendGrid

  def initialize(settings)
    @api_key = settings[:api_key]
  end

  def deliver!(mail)
    sg = SendGrid::API.new(api_key: @api_key)

    from = SendGrid::Email.new(email: mail.from.first)
    to = SendGrid::To.new(email: mail.to.first)
    subject = mail.subject
    content = SendGrid::Content.new(
      type: mail.content_type.include?('html') ? 'text/html' : 'text/plain',
      value: mail.body.decoded
    )

    sg_mail = SendGrid::Mail.new(from, subject, to, content)

    response = sg.client.mail._('send').post(request_body: sg_mail.to_json)

    unless response.status_code.to_s.match?(/^2/)
      raise "SendGrid API error: #{response.status_code} - #{response.body}"
    end

    response
  end
end

ActionMailer::Base.add_delivery_method :sendgrid, SendGridDelivery
