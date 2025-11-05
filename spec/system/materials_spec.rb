require 'rails_helper'

RSpec.describe '原材料管理', type: :system do
  let(:user) { create(:user) }
  
  before do
    sign_in_as(user)
  end

  describe '原材料一覧' do
    let!(:material1) { create(:material, name: 'まぐろ', display_order: 1, user: user) }
    let!(:material2) { create(:material, name: 'サーモン', display_order: 2, user: user) }

    it '原材料の一覧が表示される' do
      visit materials_path

      expect(page).to have_content('原材料一覧')
      expect(page).to have_content('まぐろ')
      expect(page).to have_content('サーモン')
    end

    it '原材料の単位とカテゴリが表示される' do
      visit materials_path

      # テーブル内に単位とカテゴリが表示されることを確認
      expect(page).to have_content(material1.unit_for_product.name)
      expect(page).to have_content(material1.unit_for_order.name)
      expect(page).to have_content(material1.category.name)
    end
  end

  describe '原材料詳細' do
    let!(:material) { create(:material, name: 'まぐろ', user: user) }

    it '原材料の詳細情報が表示される' do
      visit material_path(material)

      expect(page).to have_content('原材料詳細')
      expect(page).to have_content('まぐろ')
      expect(page).to have_content(material.unit_for_product.name)
      expect(page).to have_content(material.unit_for_order.name)
      expect(page).to have_content(material.category.name)
    end
  end

  describe '原材料作成' do
    it '新規作成画面が表示される' do
      visit new_material_path

      expect(page).to have_content('原材料登録')
      expect(page).to have_field('原材料名')
      expect(page).to have_content('カテゴリー')
      expect(page).to have_content('デフォルト重量')
      expect(page).to have_button('登録')
    end

    it 'バリデーションエラーが表示される' do
      visit new_material_path

      click_button '登録'

      expect(page).to have_content('原材料名 を入力してください')
    end
  end

  describe '原材料編集' do
    let!(:material) { create(:material, name: 'まぐろ', user: user) }

    it '編集画面が表示される' do
      visit edit_material_path(material)

      expect(page).to have_content('原材料編集')
      expect(page).to have_field('原材料名', with: 'まぐろ')
    end

    it 'バリデーションエラーが表示される' do
      visit edit_material_path(material)

      fill_in '原材料名', with: ''
      click_button '更新'

      expect(page).to have_content('原材料名 を入力してください')
    end
  end

  describe '原材料削除' do
    let!(:material) { create(:material, name: 'まぐろ', user: user) }

    it '原材料の削除リンクが表示される' do
      visit materials_path

      expect(page).to have_content('まぐろ')
      # rack_testドライバーではJavaScriptの確認ダイアログに対応していないため、
      # 削除リンクの存在確認のみ行う
      expect(page).to have_link('削除')
    end
  end

  describe '原材料並び替え' do
    let!(:material1) { create(:material, name: 'まぐろ', display_order: 1, user: user) }
    let!(:material2) { create(:material, name: 'サーモン', display_order: 2, user: user) }

    it '並び替えボタンが表示される' do
      visit materials_path

      # Stimulus controllerによる並び替えボタンが存在することを確認
      # rack_testドライバーではJavaScript非対応のため、ボタンの存在のみ確認
      expect(page).to have_button('並び替えモード')
    end
  end
end
