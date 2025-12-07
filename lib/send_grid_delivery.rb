# frozen_string_literal: true

require 'sendgrid-ruby'
include SendGrid

class SendGridDelivery
  def initialize(settings)
    @api_key = settings[:api_key]
  end

  def deliver!(mail)
    # SendGrid APIクライアントを初期化
    sg = SendGrid::API.new(api_key: @api_key)

    # メール本文を取得（マルチパート対応）
    body_content = if mail.multipart?
                     mail.html_part ? mail.html_part.body.decoded : mail.text_part.body.decoded
                   else
                     mail.body.decoded
                   end

    # コンテンツタイプを判定
    content_type = if mail.multipart? && mail.html_part
                     'text/html'
                   elsif mail.content_type&.include?('html')
                     'text/html'
                   else
                     'text/plain'
                   end

    # SendGrid形式でメールを構築
    from = Email.new(email: mail.from.first)
    to = Email.new(email: mail.to.first)
    content = Content.new(type: content_type, value: body_content)
    sg_mail = Mail.new(from, mail.subject, to, content)

    # SendGrid APIでメールを送信
    response = sg.client.mail._('send').post(request_body: sg_mail.to_json)

    # エラーチェック
    unless response.status_code.to_s.start_with?('2')
      raise "SendGrid API error: #{response.status_code} - #{response.body}"
    end

    response
  end
end

# ActionMailerに配信メソッドを登録
ActionMailer::Base.add_delivery_method :sendgrid, SendGridDelivery
