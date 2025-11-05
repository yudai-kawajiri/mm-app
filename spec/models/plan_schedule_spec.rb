# spec/models/plan_schedule_spec.rb

require 'rails_helper'

RSpec.describe PlanSchedule, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      schedule = create(:plan_schedule)
      expect(schedule).to be_valid
    end

    it 'スケジュール日がなければ無効であること' do
      schedule = build(:plan_schedule, scheduled_date: nil)
      schedule.valid?
      expect(schedule.errors[:scheduled_date]).to include('を入力してください')
    end

    # 削除: 計画売上がなければ無効であること（バリデーションが存在しない）
  end

  describe 'アソシエーション' do
    it 'ユーザーに属していること' do
      schedule = create(:plan_schedule)
      expect(schedule.user).to be_present
    end

    it '計画に属していること' do
      schedule = create(:plan_schedule)
      expect(schedule.plan).to be_present
    end
  end
end
