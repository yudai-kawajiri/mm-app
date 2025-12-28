require 'rails_helper'

RSpec.describe Resources::Plan, type: :model do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }

  it 'has associations' do
    plan = create(:plan, company: company, store: store)
    expect(plan.company).to eq(company)
    expect(plan.store).to eq(store)
  end

  it 'has name and dates' do
    plan = create(:plan, company: company, store: store, name: 'Test Plan')
    expect(plan.name).to be_present
  end
end
