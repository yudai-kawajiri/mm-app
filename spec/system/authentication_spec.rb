require 'rails_helper'

RSpec.describe '認証機能', type: :system do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'ログイン' do
    scenario 'ユーザーは正しい認証情報でログインできる' do
      visit new_user_session_path

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: user.password
      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
      expect(current_path).to eq(authenticated_root_path)
    end

    scenario '誤った認証情報ではログインできない' do
      visit new_user_session_path

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'wrong_password'
      click_button 'ログイン'

      expect(page).to have_content('メールアドレスまたはパスワードが違います')
      expect(current_path).to eq(new_user_session_path)
    end

    scenario '未入力ではログインできない' do
      visit new_user_session_path

      click_button 'ログイン'

      expect(page).to have_content('メールアドレスまたはパスワードが違います')
      expect(current_path).to eq(new_user_session_path)
    end
  end

  describe 'ログアウト' do
    before do
      sign_in_as(user)
    end

    scenario 'ログイン中のユーザーはログアウトできる' do
      visit authenticated_root_path

      # サイドバー内の「ログアウト」ボタン（button_to で実装されている）
      # t('devise.sessions.sign_out') の翻訳は「ログアウト」
      within '.list-group' do
        click_button 'ログアウト'
      end

      expect(page).to have_content('ログアウトしました')
      expect(current_path).to eq(root_path)
    end
  end

  describe 'アクセス制限' do
    scenario '未ログインユーザーは保護されたページにアクセスできない' do
      visit resources_categories_path

      expect(current_path).to eq(new_user_session_path)
      expect(page).to have_content('アカウント登録もしくはログインが必要です')
    end

    scenario 'ログイン後は保護されたページにアクセスできる' do
      sign_in_as(user)
      visit resources_categories_path

      expect(current_path).to eq(resources_categories_path)
      expect(page).to have_http_status(:success)
    end
  end
end
