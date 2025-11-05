# frozen_string_literal: true

require 'capybara/rspec'
require 'selenium/webdriver'

# Capybaraの基本設定
Capybara.default_max_wait_time = 5
Capybara.server = :puma, { Silent: true }

# Selenium WebDriverの設定（Headless Chrome）
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1920,1080')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# JavaScriptテスト用ドライバー設定
Capybara.javascript_driver = :headless_chrome

RSpec.configure do |config|
  # システムテストの前後処理
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :headless_chrome
  end
end