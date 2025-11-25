require 'rails_helper'

RSpec.describe 'アカウント設定', type: :system do
  let(:user) { create(:user, name: '山田太郎', email: 'test@example.com') }

  before do
    sign_in_as(user)
  end

  describe 'アカウント設定ページ' do
    it 'アカウント設定ページが表示される' do
      visit edit_user_registration_path

      expect(page).to have_content('アカウント設定')
      expect(page).to have_field('名前', with: '山田太郎')
      expect(page).to have_field('メールアドレス', with: 'test@example.com')
    end

    it 'パスワード変更フィールドが表示される' do
      visit edit_user_registration_path

      # パスワードフィールドはプレースホルダーのみでラベルがi18n管理のため、
      # フォームの存在確認に留める
      expect(page).to have_css('input[type="password"]', count: 3)
    end

    it '更新ボタンが表示される' do
      visit edit_user_registration_path

      expect(page).to have_button('更新')
    end
  end

  describe 'プロフィール更新' do
    it '名前を変更できる' do
      visit edit_user_registration_path

      fill_in '名前', with: '鈴木花子'
      fill_in '現在のパスワード', with: user.password
      click_button '更新'

      expect(page).to have_content('アカウント情報を更新しました')
      expect(user.reload.name).to eq('鈴木花子')
    end

    it '現在のパスワードなしでは更新できない' do
      visit edit_user_registration_path

      fill_in '名前', with: '鈴木花子'
      click_button '更新'

      expect(page).to have_content('現在のパスワード を入力してください')
    end
  end

  describe 'メールアドレス変更' do
    it 'メールアドレスを変更できる' do
      visit edit_user_registration_path

      fill_in 'メールアドレス', with: 'new_email@example.com'
      fill_in '現在のパスワード', with: user.password
      click_button '更新'

      expect(page).to have_content('アカウント情報を更新しました')
    end
  end

  describe 'パスワード変更' do
    it 'パスワードを変更できる' do
      visit edit_user_registration_path

      # パスワードフィールドは3つあり、順番に new, confirmation, current
      password_fields = page.all('input[type="password"]')
      password_fields[0].set('newpassword123')  # 新しいパスワード
      password_fields[1].set('newpassword123')  # 確認用
      password_fields[2].set(user.password)     # 現在のパスワード

      click_button '更新'

      expect(page).to have_content('アカウント情報を更新しました')
    end

    it 'パスワード確認が一致しない場合はエラー' do
      visit edit_user_registration_path

      # パスワードフィールドは3つあり、順番に new, confirmation, current
      password_fields = page.all('input[type="password"]')
      password_fields[0].set('newpassword123')  # 新しいパスワード
      password_fields[1].set('different123')    # 確認用（異なる値）
      password_fields[2].set(user.password)     # 現在のパスワード

      click_button '更新'

      expect(page).to have_content('パスワード（確認） とパスワードの入力が一致しません')
    end
  end

  describe 'アカウント削除' do
    it 'アカウント削除ボタンが表示される' do
      visit edit_user_registration_path

      expect(page).to have_content('アカウントを削除') | have_button('アカウントを削除')
    end
  end
end
