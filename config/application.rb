require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # ====================
    # 国際化・タイムゾーン設定
    # ====================
    # 日本語をデフォルトロケールに設定
    config.i18n.default_locale = :ja
    # locales 配下のすべての YAML ファイルを読み込み
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]
    # タイムゾーンを日本時間に設定
    config.time_zone = 'Tokyo'

    # ====================
    # Active Storage 設定
    # ====================
    # 画像のリサイズ処理に MiniMagick を使用（商品画像など）
    config.active_storage.variant_processor = :mini_magick

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
