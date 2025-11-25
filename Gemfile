source "https://rubygems.org"

# === Core ===
gem "rails", "~> 8.1.1"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

# === Assets ===
gem "propshaft"
gem "cssbundling-rails"
gem "importmap-rails"

# === Hotwire ===
gem "turbo-rails"
gem "stimulus-rails"

# === Rails 8 Solid系 ===
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"

# === Authentication ===
gem "devise", "~> 4.9"

# === View Helpers ===
gem "jbuilder"
gem "kaminari", "~> 1.2.2"
gem "bootstrap5-kaminari-views"
gem "cocoon"
gem "jquery-rails"

# === Utilities ===
gem "enum_help"
gem "image_processing", "~> 1.2"
gem "paper_trail", "~> 15.0"
gem "thruster", require: false


group :development, :test do
  gem "brakeman", require: false
  gem "byebug", platforms: [ :mri, :mingw, :x64_mingw ]
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "httparty"
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 6.1.0"
  gem "rubocop-rails-omakase", require: false
end


group :development do
  gem "web-console"
  gem "whenever", require: false

  # メール確認ツール（グローバルインストール推奨）
  # インストール: gem install mailcatcher
  # 起動: mailcatcher
  # URL: http://localhost:1080
end


group :test do
  gem "capybara"
  gem "database_cleaner-active_record"
  gem "rspec_junit_formatter"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webdrivers"
end
