require 'rails_helper'

RSpec.describe '原材料管理', type: :system do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }

  before do
    sign_in_as(user)
  end

  describe '原材料一覧' do
    let!(:material1) { create(:material, name: 'まぐろ', display_order: 1, user: user) }
    let!(:material2) { create(:material, name: 'サーモン', display_order: 2, user: user) }

    it '原材料の一覧が表示される' do
      visit "/c/#{user.company.slug}/resources/materials"

      expect(page).to have_content('原材料一覧')
      expect(page).to have_content('まぐろ')
      expect(page).to have_content('サーモン')
    end

    it '原材料の単位とカテゴリ―が表示される' do
      visit "/c/#{user.company.slug}/resources/materials"

      # テーブル内に単位とカテゴリ―が表示されることを確認
      expect(page).to have_content(material1.unit_for_product.name)
      expect(page).to have_content(material1.unit_for_order.name)
      expect(page).to have_content(material1.category.name)
    end
  end

  describe '原材料詳細' do
    let!(:material) { create(:material, name: 'まぐろ', user: user) }

    it '原材料の詳細情報が表示される' do
      visit "/c/#{user.company.slug}/resources/materials/#{material.id}"

      expect(page).to have_content('原材料詳細')
      expect(page).to have_content('まぐろ')
      expect(page).to have_content(material.unit_for_product.name)
      expect(page).to have_content(material.unit_for_order.name)
      expect(page).to have_content(material.category.name)
    end
  end

  describe '原材料作成' do
    it '新規作成画面が表示される' do
      visit "/c/#{user.company.slug}/resources/materials/new"

      expect(page).to have_content('原材料登録')
      expect(page).to have_field('原材料名')
      expect(page).to have_content('カテゴリー')
      expect(page).to have_content('基本分量')
      expect(page).to have_button('登録')
    end

    it 'バリデーションエラーが表示される' do
      visit "/c/#{user.company.slug}/resources/materials/new"

      click_button '登録'

      expect(page).to have_content('原材料名を入力してください')
    end
  end

  describe '原材料編集' do
    let!(:material) { create(:material, name: 'まぐろ', user: user) }

    it '編集画面が表示される' do
      visit "/c/#{user.company.slug}/resources/materials/#{material.id}/edit"

      expect(page).to have_content('原材料編集')
      expect(page).to have_field('原材料名', with: 'まぐろ')
    end

    it 'バリデーションエラーが表示される' do
      visit "/c/#{user.company.slug}/resources/materials/#{material.id}/edit"

      fill_in '原材料名', with: ''
      click_button '更新'

      expect(page).to have_content('原材料名を入力してください')
    end
  end

  describe '原材料削除' do
    let!(:material) { create(:material, name: 'まぐろ', user: user) }

    it '原材料の削除ボタンが表示される' do
      visit "/c/#{user.company.slug}/resources/materials/#{material.id}"

      # 削除ボタン（アイコンのみ）が存在することを確認
      expect(page).to have_css('button[data-turbo-confirm]', count: 1)
    end
  end

  describe '原材料並び替え' do
    let!(:material1) { create(:material, name: 'まぐろ', display_order: 1, user: user) }
    let!(:material2) { create(:material, name: 'サーモン', display_order: 2, user: user) }

    it 'ソート可能な一覧が表示される' do
      visit "/c/#{user.company.slug}/resources/materials"

      # Stimulus controllerのdata属性が存在することを確認
      expect(page).to have_css('[data-controller="sortable-table"]')
    end
  end
end
