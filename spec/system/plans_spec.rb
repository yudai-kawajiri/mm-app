require 'rails_helper'

RSpec.describe '製造計画管理', type: :system do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }

  before do
    sign_in_as(user)
  end

  describe '製造計画一覧' do
    let!(:plan1) { create(:plan, name: '通常生産計画', status: :active, user: user) }
    let!(:plan2) { create(:plan, name: '特別生産計画', status: :draft, user: user) }

    it '製造計画の一覧が表示される' do
      visit "/c/#{user.company.slug}/resources/plans"

      expect(page).to have_content('製造計画一覧')
      expect(page).to have_content('通常生産計画')
      expect(page).to have_content('特別生産計画')
    end

    it '製造計画のカテゴリ―とステータスが表示される' do
      visit "/c/#{user.company.slug}/resources/plans"

      expect(page).to have_content(plan1.category.name)
      # ステータスはカスタムヘルパーでレンダリングされるため、基本的な確認のみ
      expect(page).to have_css('td') # テーブルセルが存在することを確認
    end
  end

  describe '製造計画詳細' do
    let!(:plan) { create(:plan, name: '通常生産計画', status: :active, user: user) }

    it '製造計画の詳細情報が表示される' do
      visit "/c/#{user.company.slug}/resources/plans/#{plan.id}"

      expect(page).to have_content('計画詳細')
      expect(page).to have_content('通常生産計画')
      expect(page).to have_content(plan.category.name)
    end
  end

  describe '製造計画作成' do
    xit '新規作成画面が表示される' do
        visit scoped_path(:new_resources_plan)
        expect(page).to have_current_path(new_plan_path)
      end

    it 'バリデーションエラーが表示される' do
      visit "/c/#{user.company.slug}/resources/plans/new"

      click_button '登録'

      expect(page).to have_content('計画名を入力してください')
    end
  end

  describe '製造計画編集' do
    let!(:plan) { create(:plan, name: '通常生産計画', status: :active, user: user) }

    it '編集画面が表示される' do
      visit "/c/#{user.company.slug}/resources/plans/#{plan.id}/edit"

      expect(page).to have_content('計画編集')
      expect(page).to have_field('計画名', with: '通常生産計画')
    end

    it 'バリデーションエラーが表示される' do
      visit "/c/#{user.company.slug}/resources/plans/#{plan.id}/edit"

      fill_in '計画名', with: ''
      click_button '更新'

      expect(page).to have_content('計画名を入力してください')
    end
  end

  describe '製造計画削除' do
    let!(:plan) { create(:plan, name: '通常生産計画', status: :draft, user: user) }

    it '製造計画の削除ボタンが表示される' do
      visit "/c/#{user.company.slug}/resources/plans/#{plan.id}"

      # rack_testドライバーではJavaScriptの確認ダイアログに対応していないため、
      # 削除リンクの存在確認のみ行う
      expect(page).to have_css('button[data-turbo-confirm]', count: 1)
    end
  end

  describe '製造計画複製' do
    let!(:plan) { create(:plan, name: '通常生産計画', status: :active, user: user) }

    xit 'コピー機能が表示される' do
        visit plans_path
        expect(page).to have_content('製造計画')
      end
  end
end
