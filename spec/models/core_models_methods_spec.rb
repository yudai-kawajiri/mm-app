require 'rails_helper'

RSpec.describe 'Core Models Methods', type: :model do
  describe Company do
    it 'has slug' do
      company = create(:company)
      expect(company.slug).to be_present
    end

    it 'has stores association' do
      company = create(:company)
      expect(company).to respond_to(:stores)
    end

    it 'has users association' do
      company = create(:company)
      expect(company).to respond_to(:users)
    end
  end

  describe Store do
    let(:company) { create(:company) }

    it 'belongs to company' do
      store = create(:store, company: company)
      expect(store.company).to eq(company)
    end

    it 'has name and code' do
      store = create(:store, company: company, name: 'Test Store')
      expect(store.name).to eq('Test Store')
      expect(store.code).to eq('TS001')
    end

    it 'has users association' do
      store = create(:store, company: company)
      expect(store).to respond_to(:users)
    end
  end

  describe Resources::Unit do
    let(:company) { create(:company) }

    it 'belongs to company' do
      unit = create(:unit, company: company)
      expect(unit.company).to eq(company)
    end

    it 'has name' do
      unit = create(:unit, company: company, name: 'kg')
      expect(unit.name).to eq('kg')
    end
  end
end
