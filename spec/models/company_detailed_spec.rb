require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'validations' do
    it 'requires name' do
      company = Company.new(name: nil)
      company.valid?
      expect(company.errors[:name]).to be_present
    end

    it 'requires slug' do
      company = Company.new(slug: nil)
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
end
