require 'rails_helper'

RSpec.describe 'Smoke Test', type: :system do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  scenario 'トップページにアクセスできる' do
    visit "/c/#{user.company.slug}"
    expect(page).to have_http_status(:success)
  end

  # js: true のテストは一旦コメントアウト
  # scenario 'ログインページが表示される', js: true do
  #   visit new_user_session_path
  #   expect(page).to have_content('ログイン')
  #   expect(page).to have_button('ログイン')
  # end

  # JavaScript不要なテスト
  scenario 'ログインページが表示される' do
    visit new_user_session_path
    expect(page).to have_content('ログイン')
    expect(page).to have_field('user[email]')
    expect(page).to have_field('user[password]')
  end
end
