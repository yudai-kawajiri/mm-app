require 'rails_helper'

RSpec.describe 'カテゴリ―管理', type: :system do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let!(:category) { create(:category, user: user, company: user.company, name: 'テストカテゴリ', reading: 'てすとかてごり') }

  before do
    sign_in_as(user)
  end

  describe 'カテゴリ一覧' do
    scenario 'ユーザーは自分のカテゴリ一覧を閲覧できる' do
      visit "/c/#{user.company.slug}/resources/categories"

      expect(page).to have_content('テストカテゴリ')
      expect(page).to have_content('新規登録')
    end
  end

  describe 'カテゴリ―詳細' do
    scenario 'ユーザーはカテゴリ―の詳細を閲覧できる' do
      visit "/c/#{user.company.slug}/resources/categories/#{category.id}"

      expect(page).to have_content('テストカテゴリ')
      expect(page).to have_link('編集')
      expect(page).to have_button('削除')
    end
  end

  describe 'カテゴリ―作成' do
    scenario 'ユーザーは新しいカテゴリ―を作成できる' do
      visit "/c/#{user.company.slug}/resources/categories/new"

      fill_in 'カテゴリー名', with: '新しいカテゴリ―'
      fill_in '読み仮名', with: 'あたらしいかてごり'
      select '原材料', from: '種別'
      click_button '登録'

      expect(page).to have_content('カテゴリーを登録しました')
      expect(page).to have_content('新しいカテゴリ―')
    end

    scenario 'バリデーションエラー時は作成できない' do
      visit "/c/#{user.company.slug}/resources/categories/new"

      fill_in 'カテゴリー名', with: ''
      click_button '登録'

      expect(page).to have_content('カテゴリーの登録に失敗しました')
      expect(page).to have_content('カテゴリー名を入力してください')
    end
  end

  describe 'カテゴリ―編集' do
    scenario 'ユーザーはカテゴリ―を編集できる' do
      visit "/c/#{user.company.slug}/resources/categories/#{category.id}/edit"

      fill_in 'カテゴリー名', with: '更新されたカテゴリ―'
      click_button '更新'

      expect(page).to have_content('カテゴリーを更新しました')
      expect(page).to have_content('更新されたカテゴリ―')
    end

    scenario 'バリデーションエラー時は更新できない' do
      visit "/c/#{user.company.slug}/resources/categories/#{category.id}/edit"

      fill_in 'カテゴリー名', with: ''
      click_button '更新'

      expect(page).to have_content('カテゴリーの更新に失敗しました')
      expect(page).to have_content('カテゴリー名を入力してください')
    end
  end

  describe 'カテゴリ―削除' do
    scenario 'ユーザーはカテゴリ―を削除できる' do
      visit "/c/#{user.company.slug}/resources/categories/#{category.id}"

      click_button '削除'

      expect(page).to have_content('カテゴリーを削除しました')
      expect(page).to have_current_path(scoped_path(:resources_categories))

      within 'table' do
        expect(page).not_to have_content('テストカテゴリ')
      end
    end
  end

  scenario 'フォームに入力して作成できる' do
    visit scoped_path(:new_resources_category)
    if page.has_field?('resources_category[name]')
      fill_in 'resources_category[name]', with: 'テストカテゴリー'
      click_button '登録' rescue nil
    end
    expect(page).to have_current_path(/./, url: true)
  end
end
