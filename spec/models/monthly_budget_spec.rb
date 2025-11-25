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

    it '同じユーザーで同じ月の予算が重複していれば無効であること' do
      user = create(:user)
      create(:monthly_budget, user: user, budget_month: Date.current.beginning_of_month)
      budget = build(:monthly_budget, user: user, budget_month: Date.current.beginning_of_month)
      budget.valid?
      expect(budget.errors[:budget_month]).to be_present
    end

    it '異なるユーザーであれば同じ月でも有効であること' do
      user1 = create(:user)
      user2 = create(:user)
      create(:monthly_budget, user: user1, budget_month: Date.current.beginning_of_month)
      budget = build(:monthly_budget, user: user2, budget_month: Date.current.beginning_of_month)
      expect(budget).to be_valid
    end
  end

  describe 'アソシエーション' do
    it 'ユーザーに属していること' do
      budget = create(:monthly_budget)
      expect(budget.user).to be_present
    end
  end
end
