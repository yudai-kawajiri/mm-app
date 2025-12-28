require 'rails_helper'

RSpec.describe '認証機能', type: :system do
  let(:company) { create(:company) }
  let(:user) { create(:user, email: 'test@example.com', password: 'password123', company: company) }

  describe 'ログイン' do
    scenario 'ユーザーは正しい認証情報でログインできる' do
      visit "/c/#{user.company.slug}/users/sign_in"

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: user.password
      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
      expect(current_path).to eq(scoped_path(:dashboards))
    end

    scenario '誤った認証情報ではログインできない' do
      visit "/c/#{user.company.slug}/users/sign_in"

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'wrong_password'
      click_button 'ログイン'

      expect(page).to have_content('メールアドレスまたはパスワードが違います')
      expect(current_path).to eq("/c/#{user.company.slug}/users/sign_in")
    end

    xscenario '未入力ではログインできない' do
        visit new_user_session_path
        click_button 'ログイン'
        expect(page).to have_current_path(new_user_session_path)
      end
    end



  describe 'アクセス制限' do
    xscenario '未ログインユーザーは保護されたページにアクセスできない' do
      visit "/c/#{user.company.slug}/resources/categories"

      expect(current_path).to eq("/c/#{user.company.slug}/users/sign_in")
      expect(page).to have_content('アカウント登録もしくはログインが必要です')
    end

    scenario 'ログイン後は保護されたページにアクセスできる' do
      sign_in_as(user)
      visit "/c/#{user.company.slug}/resources/categories"

      expect(current_path).to eq(scoped_path(:resources_categories))
      expect(page).to have_http_status(:success)
end
end
end
