require 'rails_helper'

RSpec.describe 'ダッシュボード', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in_as(user)
  end

  describe 'ダッシュボード表示' do
    it 'ダッシュボードページが表示される' do
      visit root_path

      expect(page).to have_content(user.name)
      expect(page).to have_content('ようこそ') | have_content('ダッシュボード')
    end

    it '月次選択フォームが表示される' do
      visit root_path

      expect(page).to have_select('year')
      expect(page).to have_select('month')
      expect(page).to have_button('表示')
    end

    it '現在の年月が選択されている' do
      visit root_path

      current_year = Date.current.year
      current_month = Date.current.month

      expect(page).to have_select('year', selected: "#{current_year}年")
      expect(page).to have_select('month', selected: "#{current_month}月")
    end
  end

  describe '月次選択機能' do
    it '異なる月を選択して表示できる' do
      visit root_path

      select '2024年', from: 'year'
      select '12月', from: 'month'
      click_button '表示'

      expect(page).to have_select('year', selected: '2024年')
      expect(page).to have_select('month', selected: '12月')
    end
  end

  describe '予算サマリー表示' do
    let!(:monthly_budget) do
      create(:monthly_budget,
        user: user,
        budget_month: Date.current.beginning_of_month,
        target_amount: 1000000
      )
    end

    it '月次予算情報が表示される' do
      visit root_path

      # サマリーカードが表示されることを確認
      expect(page).to have_css('.card') | have_css('.summary-card')
    end
  end
end
