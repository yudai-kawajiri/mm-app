require 'rails_helper'

RSpec.describe Planning::PlanSchedule, type: :model do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:plan) { create(:plan, company: company) }

  it 'belongs to plan' do
    schedule = Planning::PlanSchedule.new(
      plan: plan,
      company: company,
      scheduled_date: Date.today
    )
    expect(schedule.plan).to eq(plan)
  end

  it 'has scheduled_date' do
    schedule = Planning::PlanSchedule.new(scheduled_date: Date.today)
    expect(schedule.scheduled_date).to be_present
  end
end
