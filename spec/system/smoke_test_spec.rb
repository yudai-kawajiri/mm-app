require 'rails_helper'

RSpec.describe 'Smoke Test', type: :system do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }

  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  scenario 'トップページにアクセスできる' do
        visit root_path
        expect([ 200, 302 ]).to include(page.status_code)
      end

  # js: true のテストは一旦コメントアウト
  # scenario 'ログインページが表示される', js: true do
  #   visit "/c/#{user.company.slug}/users/sign_in"
  #   expect(page).to have_content('ログイン')
  #   expect(page).to have_button('ログイン')
  # end

  # JavaScript不要なテスト
  scenario 'ログインページが表示される' do
    visit "/c/#{user.company.slug}/users/sign_in"
    expect(page).to have_content('ログイン')
    expect(page).to have_field('user[email]')
    expect(page).to have_field('user[password]')
  end
end
