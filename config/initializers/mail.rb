# frozen_string_literal: true

if Rails.env.production?
  Rails.application.config.action_mailer.tap do |config|
    # SendGrid Web APIを使用
    if ENV["SENDGRID_API_KEY"].present?
      config.delivery_method = :sendgrid_actionmailer
      config.sendgrid_actionmailer_settings = {
        api_key: ENV["SENDGRID_API_KEY"],
        raise_delivery_errors: true
      }
      Rails.logger.info "===== Using SendGrid ActionMailer gem ====="
    else
      # フォールバック: SMTP設定
      config.delivery_method = :smtp
      config.perform_deliveries = true
      config.raise_delivery_errors = true
      config.smtp_settings = {
        address: ENV.fetch("SMTP_ADDRESS", "smtp.sendgrid.net"),
        port: ENV.fetch("SMTP_PORT", "587").to_i,
        domain: ENV.fetch("SMTP_DOMAIN", "www.mm-app-system.com"),
        user_name: ENV.fetch("SMTP_USER_NAME", "apikey"),
        password: ENV["SMTP_PASSWORD"],
        authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain"),
        enable_starttls_auto: ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO", "true") == "true"
      }
      Rails.logger.info "===== Using SMTP fallback ====="
    end

    # 本番環境のURL設定
    config.default_url_options = { host: ENV.fetch("APP_HOST", "www.mm-app-system.com") }

    # デフォルトの送信元メールアドレス
    config.default_options = { from: ENV.fetch("MAILER_FROM", "mmapp@outlook.jp") }
  end
end
