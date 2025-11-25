require 'rails_helper'

RSpec.describe 'カテゴリ管理', type: :system do
  let(:user) { create(:user) }
  let!(:category) { create(:category, name: 'テストカテゴリ', user: user) }

  before do
    sign_in_as(user)
  end

  describe 'カテゴリ一覧' do
    scenario 'ユーザーは自分のカテゴリ一覧を閲覧できる' do
      visit resources_categories_path

      expect(page).to have_content('テストカテゴリ')
      expect(page).to have_link('新規作成')
    end
  end

  describe 'カテゴリ詳細' do
    scenario 'ユーザーはカテゴリの詳細を閲覧できる' do
      visit resources_category_path(category)

      expect(page).to have_content('テストカテゴリ')
      expect(page).to have_link('編集')
      expect(page).to have_button('削除')
    end
  end

  describe 'カテゴリ作成' do
    scenario 'ユーザーは新しいカテゴリを作成できる' do
      visit new_resources_category_path

      fill_in 'category[name]', with: '新しいカテゴリ'
      click_button '登録'

      expect(page).to have_content('「新しいカテゴリ」を作成しました')
      expect(page).to have_content('新しいカテゴリ')
    end

    scenario 'バリデーションエラー時は作成できない' do
      visit new_resources_category_path

      fill_in 'category[name]', with: ''
      click_button '登録'

      expect(page).to have_content('カテゴリーの作成に失敗しました')
      expect(page).to have_content('カテゴリー名 を入力してください')
    end
  end

  describe 'カテゴリ編集' do
    scenario 'ユーザーはカテゴリを編集できる' do
      visit edit_resources_category_path(category)

      fill_in 'category[name]', with: '更新されたカテゴリ'
      click_button '更新'

      expect(page).to have_content('「更新されたカテゴリ」を更新しました')
      expect(page).to have_content('更新されたカテゴリ')
    end

    scenario 'バリデーションエラー時は更新できない' do
      visit edit_resources_category_path(category)

      fill_in 'category[name]', with: ''
      click_button '更新'

      expect(page).to have_content('カテゴリーの更新に失敗しました')
      expect(page).to have_content('カテゴリー名 を入力してください')
    end
  end

  describe 'カテゴリ削除' do
    scenario 'ユーザーはカテゴリを削除できる' do
      visit resources_category_path(category)

      click_button '削除'

      expect(page).to have_content('「テストカテゴリ」を削除しました')
      expect(page).to have_current_path(resources_categories_path)

      # テーブル内に削除したカテゴリが存在しないことを確認
      # フラッシュメッセージには含まれるが、テーブル内には存在しない
      within 'table' do
        expect(page).not_to have_content('テストカテゴリ')
      end
    end
  end
end
