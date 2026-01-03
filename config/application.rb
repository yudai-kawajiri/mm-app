require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])

    # 国際化設定
    config.i18n.default_locale = :ja
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]

    # タイムゾーン設定
    config.time_zone = "Tokyo"

    # マルチテナント対応: localhost でサブドメインを検出
    # 例: d-1.localhost → subdomain: "d-1"
    config.action_dispatch.tld_length = 0

    # 画像処理
    config.active_storage.variant_processor = :mini_magick
  end
end
