require 'rails_helper'

RSpec.describe '製品管理', type: :system do
  let(:user) { create(:user) }
  let(:category) { create(:category, name: 'テストカテゴリ', user: user) }
  let!(:product) { create(:product, name: 'まぐろ握り', price: 300, category: category, user: user) }

  before do
    sign_in_as(user)
  end

  describe '製品一覧' do
    scenario 'ユーザーは自分の製品一覧を閲覧できる' do
      visit products_path

      expect(page).to have_content('まぐろ握り')
      expect(page).to have_content('300')
      expect(page).to have_link('新規作成')
    end

    scenario '製品が存在しない場合でも一覧ページが表示される' do
      product.destroy
      visit products_path

      expect(page).to have_content('商品一覧')
      expect(page).to have_link('新規作成')
    end
  end

  describe '製品詳細' do
    scenario 'ユーザーは製品の詳細を閲覧できる' do
      visit product_path(product)

      expect(page).to have_content('まぐろ握り')
      expect(page).to have_content('300')
      expect(page).to have_link('編集')
    end
  end

  describe '製品作成' do
    scenario '作成フォームにアクセスできる' do
      visit new_product_path

      expect(page).to have_field('product[name]')
      expect(page).to have_field('product[price]')
      expect(page).to have_button('登録')
    end

    scenario 'バリデーションエラー時は作成できない' do
      visit new_product_path

      fill_in 'product[name]', with: ''
      click_button '登録'

      expect(page).to have_content('商品の作成に失敗しました')
      expect(page).to have_content('商品名 を入力してください')
    end

    scenario '価格が負の値の場合は作成できない' do
      visit new_product_path

      fill_in 'product[name]', with: 'テスト製品'
      fill_in 'product[price]', with: -100
      click_button '登録'

      expect(page).to have_content('商品の作成に失敗しました')
      expect(page).to have_content('は0より大きい値を入力してください')
    end
  end

  describe '製品編集' do
    scenario 'ユーザーは製品を編集できる' do
      visit edit_product_path(product)

      fill_in 'product[name]', with: '大トロ握り'
      fill_in 'product[price]', with: 500
      click_button '更新'

      expect(page).to have_content('「大トロ握り」を更新しました')
      expect(page).to have_content('大トロ握り')
      expect(page).to have_content('500')
    end

    scenario 'バリデーションエラー時は更新できない' do
      visit edit_product_path(product)

      fill_in 'product[name]', with: ''
      click_button '更新'

      expect(page).to have_content('商品の更新に失敗しました')
      expect(page).to have_content('商品名 を入力してください')
    end
  end

  describe '製品削除' do
    scenario 'ユーザーは製品を削除できる' do
      visit product_path(product)

      click_button '削除'

      expect(page).to have_content('「まぐろ握り」を削除しました')
      expect(page).to have_current_path(products_path)

      within 'table' do
        expect(page).not_to have_content('まぐろ握り')
      end
    end
  end

  describe '製品並び替え' do
    let!(:product2) { create(:product, name: 'サーモン握り', display_order: 2, user: user) }
    let!(:product3) { create(:product, name: 'えび握り', display_order: 3, user: user) }

    scenario 'ユーザーは製品の一覧で並び替えモードを確認できる' do
      visit products_path

      expect(page).to have_content('並び替えモード')
      expect(page).to have_content('まぐろ握り')
      expect(page).to have_content('サーモン握り')
      expect(page).to have_content('えび握り')
    end
  end
end
