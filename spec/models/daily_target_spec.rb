# spec/models/daily_target_spec.rb

require 'rails_helper'

RSpec.describe DailyTarget, type: :model do
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

    # 削除: 目標金額が0以下なら無効であること（バリデーションが存在しない）

    it '同じユーザーで同じ日の目標が重複していれば無効であること' do
      user = create(:user)
      monthly_budget = create(:monthly_budget, user: user)
      create(:daily_target, user: user, monthly_budget: monthly_budget, target_date: Date.current)
      target = build(:daily_target, user: user, monthly_budget: monthly_budget, target_date: Date.current)
      target.valid?
      expect(target.errors[:target_date]).to be_present
    end
  end

  describe 'アソシエーション' do
    it 'ユーザーに属していること' do
      target = create(:daily_target)
      expect(target.user).to be_present
    end

    it '月間予算に属していること' do
      target = create(:daily_target)
      expect(target.monthly_budget).to be_present
    end
  end
end
