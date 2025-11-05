# spec/models/plan_spec.rb

require 'rails_helper'

RSpec.describe Plan, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      plan = create(:plan)
      expect(plan).to be_valid
    end

    it 'ステータスがなければ無効であること' do
      plan = build(:plan, status: nil)
      plan.valid?
      expect(plan.errors[:status]).to include('を入力してください')
    end

    it 'カテゴリがなければ無効であること' do
      plan = build(:plan, category: nil)
      plan.valid?
      expect(plan.errors[:category]).to include('を入力してください')
    end

    it 'ステータスがなければ無効であること' do
      plan = build(:plan, status: nil)
      plan.valid?
      expect(plan.errors[:status]).to include('を入力してください')
    end
  end

  describe 'enum' do
    it 'statusがdraftであること' do
      plan = create(:plan, :draft)
      expect(plan.status).to eq('draft')
      expect(plan.draft?).to be true
    end

    it 'statusがactiveであること' do
      plan = create(:plan, :active)
      expect(plan.status).to eq('active')
      expect(plan.active?).to be true
    end

    it 'statusがcompletedであること' do
      plan = create(:plan, :completed)
      expect(plan.status).to eq('completed')
      expect(plan.completed?).to be true
    end
  end

  describe 'アソシエーション' do
    it 'カテゴリに属していること' do
      plan = create(:plan)
      expect(plan.category).to be_present
    end

    it 'ユーザーに属していること' do
      plan = create(:plan)
      expect(plan.user).to be_present
    end
  end
end
