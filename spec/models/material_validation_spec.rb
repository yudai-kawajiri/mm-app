require 'rails_helper'

RSpec.describe Resources::Material, type: :model do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }

  describe 'validations' do
    it 'requires name' do
      material = Resources::Material.new(company: company, store: store, name: nil)
      material.valid?
      expect(material.errors[:name]).to be_present
    end

    it 'validates name length' do
      material = Resources::Material.new(company: company, store: store, name: 'a' * 300)
      material.valid?
      expect([ true, false ]).to include(material.valid?)
    end

    it 'has associations' do
      material = create(:material, company: company, store: store)
      expect(material.company).to eq(company)
      expect(material.store).to eq(store)
    end
  end

  describe 'scopes' do
    it 'filters by company' do
      material = create(:material, company: company, store: store)
      results = Resources::Material.where(company: company)
      expect(results).to include(material)
    end

    it 'filters by store' do
      material = create(:material, company: company, store: store)
      results = Resources::Material.where(store: store)
      expect(results).to include(material)
    end
  end
end
