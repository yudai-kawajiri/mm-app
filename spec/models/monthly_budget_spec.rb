# spec/models/monthly_budget_spec.rb

require 'rails_helper'

RSpec.describe Management::MonthlyBudget, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      budget = create(:monthly_budget)
      expect(budget).to be_valid
    end

    it '予算月がなければ無効であること' do
      budget = build(:monthly_budget, budget_month: nil)
      budget.valid?
      expect(budget.errors[:budget_month]).to include('を入力してください')
    end

    it '目標金額がなければ無効であること' do
      budget = build(:monthly_budget, target_amount: nil)
      budget.valid?
      expect(budget.errors[:target_amount]).to include('を入力してください')
    end

    it '目標金額が0以下なら無効であること' do
      budget = build(:monthly_budget, target_amount: 0)
      budget.valid?
      expect(budget.errors[:target_amount]).to be_present
    end

    it '同じ月の予算が重複していれば無効であること' do
      specific_month = Date.new(2025, 6, 1)
      create(:monthly_budget, budget_month: specific_month)
      budget = build(:monthly_budget, budget_month: specific_month)
      budget.valid?
      expect(budget.errors[:budget_month]).to be_present
    end
  end

  describe 'アソシエーション' do
    it 'ユーザーとの関連が任意であること' do
      budget = create(:monthly_budget, user: nil)
      expect(budget).to be_valid
      expect(budget.user).to be_nil
    end

    it 'ユーザーを設定できること' do
      user = create(:user)
      budget = create(:monthly_budget, user: user)
      expect(budget.user).to eq(user)
    end
  end
end
