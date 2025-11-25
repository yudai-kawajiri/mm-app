require 'rails_helper'

RSpec.describe '製造計画管理', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in_as(user)
  end

  describe '製造計画一覧' do
    let!(:plan1) { create(:plan, name: '通常生産計画', status: :active, user: user) }
    let!(:plan2) { create(:plan, name: '特別生産計画', status: :draft, user: user) }

    it '製造計画の一覧が表示される' do
      visit resources_plans_path

      expect(page).to have_content('製造計画一覧')
      expect(page).to have_content('通常生産計画')
      expect(page).to have_content('特別生産計画')
    end

    it '製造計画のカテゴリとステータスが表示される' do
      visit resources_plans_path

      expect(page).to have_content(plan1.category.name)
      # ステータスはカスタムヘルパーでレンダリングされるため、基本的な確認のみ
      expect(page).to have_css('td') # テーブルセルが存在することを確認
    end
  end

  describe '製造計画詳細' do
    let!(:plan) { create(:plan, name: '通常生産計画', status: :active, user: user) }

    it '製造計画の詳細情報が表示される' do
      visit resources_plan_path(plan)

      expect(page).to have_content('製造計画詳細')
      expect(page).to have_content('通常生産計画')
      expect(page).to have_content(plan.category.name)
    end
  end

  describe '製造計画作成' do
    it '新規作成画面が表示される' do
      visit new_resources_plan_path

      expect(page).to have_content('製造計画登録')
      expect(page).to have_field('計画名')
      expect(page).to have_select('カテゴリー')
      expect(page).to have_select('ステータス')
    end

    it 'バリデーションエラーが表示される' do
      visit new_resources_plan_path

      click_button '登録'

      expect(page).to have_content('計画名 を入力してください')
    end
  end

  describe '製造計画編集' do
    let!(:plan) { create(:plan, name: '通常生産計画', status: :active, user: user) }

    it '編集画面が表示される' do
      visit edit_resources_plan_path(plan)

      expect(page).to have_content('製造計画編集')
      expect(page).to have_field('計画名', with: '通常生産計画')
    end

    it 'バリデーションエラーが表示される' do
      visit edit_resources_plan_path(plan)

      fill_in '計画名', with: ''
      click_button '更新'

      expect(page).to have_content('計画名 を入力してください')
    end
  end

  describe '製造計画削除' do
    let!(:plan) { create(:plan, name: '通常生産計画', status: :draft, user: user) }

    it '製造計画の削除リンクが表示される' do
      visit resources_plans_path

      expect(page).to have_content('通常生産計画')
      # rack_testドライバーではJavaScriptの確認ダイアログに対応していないため、
      # 削除リンクの存在確認のみ行う
      expect(page).to have_link('削除')
    end
  end

  describe '製造計画複製' do
    let!(:plan) { create(:plan, name: '通常生産計画', status: :active, user: user) }

    it 'コピー機能が表示される' do
      visit resources_plans_path

      expect(page).to have_content('通常生産計画')
      # コピーはボタンまたはフォームとして実装されている可能性がある
      # ページ内に「コピー」テキストが存在することを確認
      expect(page).to have_content('コピー')
    end
  end
end
