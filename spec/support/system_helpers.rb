# frozen_string_literal: true

module SystemHelpers
  # ログインヘルパー
  def sign_in_as(user)
    visit "/c/#{user.company.slug}/users/sign_in"
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: user.password
    click_button 'ログイン'
  end

  # スクリーンショット保存（デバッグ用）
  def take_screenshot(name = 'screenshot')
    page.save_screenshot("tmp/screenshots/#{name}_#{Time.now.to_i}.png")
  end

  # モーダルが表示されるまで待機
  def wait_for_modal
    expect(page).to have_css('.modal', visible: true, wait: 5)
  end

  # Ajaxリクエスト完了を待機
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('typeof jQuery === "undefined" || jQuery.active === 0')
    end
  end

  # フラッシュメッセージ確認
  def expect_flash_message(message, type: :notice)
    within '.flash' do
      expect(page).to have_css(".alert-#{type}", text: message)
    end
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
