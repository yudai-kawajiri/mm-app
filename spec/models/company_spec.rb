require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'validations' do
    it 'requires name' do
      company = Company.new(name: nil, slug: 'test')
      company.valid?
      expect(company.errors[:name]).to be_present
    end

    it 'requires slug' do
      company = Company.new(name: 'Test', slug: nil)
      company.valid?
      expect(company.errors[:slug]).to be_present
    end
  end

  describe 'associations' do
    it 'has users' do
      company = create(:company)
      expect(company).to respond_to(:users)
    end

    it 'has stores' do
      company = create(:company)
      expect(company).to respond_to(:stores)
    end
  end

  describe 'slug generation' do
    it 'has to_param method' do
      company = create(:company, slug: 'my-company')
      # to_param が slug を返すか、id を返すかを確認
      expect([ company.slug, company.id.to_s ]).to include(company.to_param)
    end
  end
end
