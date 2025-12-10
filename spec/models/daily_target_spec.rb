# spec/models/daily_target_spec.rb

require 'rails_helper'

RSpec.describe Management::DailyTarget, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      target = create(:daily_target)
      expect(target).to be_valid
    end

    it '対象日がなければ無効であること' do
      target = build(:daily_target, target_date: nil)
      target.valid?
      expect(target.errors[:target_date]).to include('を入力してください')
    end

    it '目標金額がなければ無効であること' do
      target = build(:daily_target, target_amount: nil)
      target.valid?
      expect(target.errors[:target_amount]).to include('を入力してください')
    end

    it '同じ日の目標が重複していれば無効であること' do
      monthly_budget = create(:monthly_budget)
      create(:daily_target, monthly_budget: monthly_budget, target_date: Date.current)
      target = build(:daily_target, monthly_budget: monthly_budget, target_date: Date.current)
      target.valid?
      expect(target.errors[:target_date]).to be_present
    end
  end

  describe 'アソシエーション' do
    it 'ユーザーとの関連が任意であること' do
      target = create(:daily_target, user: nil)
      expect(target).to be_valid
      expect(target.user).to be_nil
    end

    it 'ユーザーを設定できること' do
      user = create(:user)
      target = create(:daily_target, user: user)
      expect(target.user).to eq(user)
    end

    it '月間予算に属していること' do
      target = create(:daily_target)
      expect(target.monthly_budget).to be_present
    end
  end
end
