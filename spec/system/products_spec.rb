require 'rails_helper'

RSpec.describe '製品管理', type: :system do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }

  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:category) { create(:category, name: 'テストカテゴリ―', user: user) }
  let!(:product) { create(:product, name: 'まぐろ握り', price: 300, category: category, user: user) }

  before do
    sign_in_as(user)
  end

  describe '製品一覧' do
    scenario 'ユーザーは自分の製品一覧を閲覧できる' do
      visit "/c/#{user.company.slug}/resources/products"

      expect(page).to have_content('まぐろ握り')
      expect(page).to have_content('300')
      expect(page).to have_content('新規登録')
    end

    xscenario '製品が存在しない場合でも一覧ページが表示される' do
      visit products_path
      expect(page).to have_current_path(products_path)
    end
  end

  describe '製品作成' do
    scenario '作成フォームにアクセスできる' do
      visit "/c/#{user.company.slug}/resources/products/new"

      expect(page).to have_field('商品名')
      expect(page).to have_field('売価')
      expect(page).to have_button('登録')
    end

    xscenario 'バリデーションエラー時は作成できない' do
      visit "/c/#{user.company.slug}/resources/products/new"

      fill_in '商品名', with: ''
      click_button '登録'

      expect(page).to have_content('商品の登録に失敗しました')
      expect(page).to have_content('商品名を入力してください')
    end

    scenario '価格が負の値の場合は作成できない' do
      visit "/c/#{user.company.slug}/resources/products/new"

      fill_in '商品名', with: 'テスト製品'
      fill_in '売価', with: -100
      click_button '登録'

      expect(page).to have_content('商品の登録に失敗しました')
      expect(page).to have_content('は0より大きい値にしてください')
    end
  end

  describe '製品編集' do
    scenario 'ユーザーは製品を編集できる' do
      page.driver.submit :patch, scoped_path(:resources_product, product), {
        resources_product: {
          name: '大トロ握り',
          reading: 'おおとろにぎり',
          item_number: product.item_number,
          price: 500,
          category_id: category.id,
          status: 'selling'
        }
      }

      visit "/c/#{user.company.slug}/resources/products/#{product.id}"

      expect(page).to have_content('大トロ握り')
      expect(page).to have_content('500')
    end

    scenario 'バリデーションエラー時は更新できない' do
      visit "/c/#{user.company.slug}/resources/products/#{product.id}/edit"

      fill_in '商品名', with: ''
      click_button '更新'

      expect(page).to have_content('商品の更新に失敗しました')
      expect(page).to have_content('商品名を入力してください')
    end
  end

  describe '製品削除' do
    scenario 'ユーザーは製品を削除できる' do
      visit "/c/#{user.company.slug}/resources/products/#{product.id}"

      click_button '削除'

      expect(page).to have_content('商品を削除しました')
      expect(page.current_path).to match(%r{/resources/products$})

      within 'table' do
        expect(page).not_to have_content('まぐろ握り')
      end
    end
  end

  describe '製品並び替え' do
    let!(:product2) { create(:product, name: 'サーモン握り', display_order: 2, user: user) }
    let!(:product3) { create(:product, name: 'えび握り', display_order: 3, user: user) }

    xit "ユーザーは製品の一覧でソート可能な一覧を確認できる" do
      visit "/c/#{user.company.slug}/resources/products"

      expect(page).to have_css('[data-controller="sortable-table"]')
      expect(page).to have_content('まぐろ握り')
      expect(page).to have_content('サーモン握り')
      expect(page).to have_content('えび握り')
    end
  end
end
