# frozen_string_literal: true

# メール設定
Rails.application.configure do
  # 本番環境でのメール送信設定
  if Rails.env.production?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.default_url_options = { host: ENV.fetch('APP_HOST', 'mm-app-gpon-orrenderr.com') }

    config.action_mailer.smtp_settings = {
      address:              ENV.fetch('SMTP_ADDRESS', 'smtp.sendgrid.net'),
      port:                 ENV.fetch('SMTP_PORT', 587).to_i,
      domain:               ENV.fetch('SMTP_DOMAIN', 'mm-app-gpih.onrender.com'),
      user_name:            ENV.fetch('SMTP_USER_NAME', 'apikey'),
      password:             ENV['SMTP_PASSWORD'],
      authentication:       ENV.fetch('SMTP_AUTHENTICATION', 'plain'),
      enable_starttls_auto: ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', 'true') == 'true'
    }

    # デフォルトの送信元アドレス
    config.action_mailer.default_options = {
      from: ENV.fetch('MAILER_FROM', 'mmapp@outlook.jp')
    }
  end
end
