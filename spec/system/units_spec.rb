require 'rails_helper'

RSpec.describe '単位管理', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in_as(user)
  end

  describe '単位一覧' do
    let!(:unit1) { create(:unit, name: 'kg', category: :production, user: user) }
    let!(:unit2) { create(:unit, name: '箱', category: :ordering, user: user) }

    it '単位の一覧が表示される' do
      visit resources_units_path

      expect(page).to have_content('単位一覧')
      expect(page).to have_content('kg')
      expect(page).to have_content('箱')
    end

    it '単位のカテゴリ―が表示される' do
      visit resources_units_path

      # enumの翻訳が表示されることを確認
      expect(page).to have_content('使用単位')
      expect(page).to have_content('発注単位')
    end
  end

  describe '単位詳細' do
    let!(:unit) { create(:unit, name: 'kg', category: :production, user: user) }

    it '単位の詳細情報が表示される' do
      visit resources_unit_path(unit)

      expect(page).to have_content('単位詳細')
      expect(page).to have_content('kg')
      expect(page).to have_content('使用単位')
    end
  end

  describe '単位作成' do
    it '新規作成画面が表示される' do
      visit new_resources_unit_path

      expect(page).to have_content('単位登録')
      expect(page).to have_field('単位名')
      expect(page).to have_select('カテゴリ―')
      expect(page).to have_button('登録')
    end

    it 'バリデーションエラーが表示される' do
      visit new_resources_unit_path

      click_button '登録'

      expect(page).to have_content('単位名 を入力してください')
    end
  end

  describe '単位編集' do
    let!(:unit) { create(:unit, name: 'kg', category: :production, user: user) }

    it '編集画面が表示される' do
      visit edit_resources_unit_path(unit)

      expect(page).to have_content('単位編集')
      expect(page).to have_field('単位名', with: 'kg')
    end

    it 'バリデーションエラーが表示される' do
      visit edit_resources_unit_path(unit)

      fill_in '単位名', with: ''
      click_button '更新'

      expect(page).to have_content('単位名 を入力してください')
    end
  end

  describe '単位削除' do
    let!(:unit) { create(:unit, name: 'kg', category: :production, user: user) }

    it '単位の削除ボタンが表示される' do
      visit resources_unit_path(unit)

      # rack_testドライバーではJavaScriptの確認ダイアログに対応していないため、
      # 削除ボタンの存在確認のみ行う
      expect(page).to have_css('button[data-turbo-confirm]', minimum: 1)
    end
  end
end
