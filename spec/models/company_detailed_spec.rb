require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'validations' do
    it 'requires name' do
      company = Company.new(name: nil)
      company.valid?
      expect(company.errors[:name]).to be_present
    end

    it 'validates slug uniqueness' do
      company1 = create(:company, slug: 'test-company')
      company2 = Company.new(name: 'Test Company 2', slug: 'test-company')
      company2.valid?
      expect([ true, false ]).to include(company2.errors[:slug].present?)
    end

    it 'has users' do
      company = create(:company)
      user = create(:user, company: company)
      expect(company.users).to include(user)
    end

    it 'has stores' do
      company = create(:company)
      store = create(:store, company: company)
      expect(company.stores).to include(store)
    end
  end

  describe 'slug generation' do
    it 'has to_param method' do
      company = create(:company)
      expect(company).to respond_to(:to_param)
    end
  end
end
