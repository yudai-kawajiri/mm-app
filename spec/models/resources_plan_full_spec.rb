require 'rails_helper'

RSpec.describe Resources::Plan, type: :model do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }

  describe 'plan operations' do
    it 'can be instantiated' do
      plan = Resources::Plan.new(
        company: company,
        store: store,
        name: 'Test Plan'
      )
      expect(plan).to be_a(Resources::Plan)
    end
  end

  describe 'associations' do
    it 'has associations' do
      plan = Resources::Plan.new
      expect(plan).to respond_to(:company)
      expect(plan).to respond_to(:store)
      expect(plan).to respond_to(:plan_products)
    end
  end

  describe 'validations' do
    it 'validates presence of required fields' do
      plan = Resources::Plan.new
      plan.valid?
      expect(plan.errors).to be_present
    end
  end
end
