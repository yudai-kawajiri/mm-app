# frozen_string_literal: true

# SendGrid配信メソッドを読み込み
require Rails.root.join('lib/send_grid_delivery')

# メール設定
if Rails.env.production?
  Rails.application.config.action_mailer.tap do |config|
    # デバッグログを追加
    Rails.logger.info "===== SENDGRID DEBUG ====="
    Rails.logger.info "SENDGRID_API_KEY present?: #{ENV['SENDGRID_API_KEY'].present?}"
    Rails.logger.info "SENDGRID_API_KEY value: #{ENV['SENDGRID_API_KEY']&.slice(0, 10)}..." if ENV['SENDGRID_API_KEY'].present?
    Rails.logger.info "=========================="

    # SendGrid Web APIを使用する場合（推奨）
    if ENV['SENDGRID_API_KEY'].present?
      config.delivery_method = :sendgrid
      config.sendgrid_settings = {
        api_key: ENV['SENDGRID_API_KEY']
      }
      Rails.logger.info "Using SendGrid Web API"
    else
      # フォールバック: SMTP設定（環境変数が設定されていない場合）
      config.delivery_method = :smtp
      config.perform_deliveries = true
      config.raise_delivery_errors = true
      config.smtp_settings = {
        address: ENV.fetch('SMTP_ADDRESS', 'smtp.sendgrid.net'),
        port: ENV.fetch('SMTP_PORT', '587').to_i,
        domain: ENV.fetch('SMTP_DOMAIN', 'mm-app-gpih.onrender.com'),
        user_name: ENV.fetch('SMTP_USER_NAME', 'apikey'),
        password: ENV['SMTP_PASSWORD'],
        authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain'),
        enable_starttls_auto: ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', 'true') == 'true'
      }
      Rails.logger.info "Using SMTP fallback"
    end

    # 本番環境のURL設定
    config.default_url_options = { host: ENV.fetch('APP_HOST', 'mm-app-gpih.onrender.com') }

    # デフォルトの送信元メールアドレス
    config.default_options = { from: ENV.fetch('MAILER_FROM', 'mmapp@outlook.jp') }
  end
end
