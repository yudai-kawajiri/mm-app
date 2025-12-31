require 'rails_helper'

RSpec.describe Resources::Category, type: :model do
  let(:company) { create(:company) }
  
  describe 'validations' do
    it 'requires name' do
      category = Resources::Category.new(name: nil, company: company)
      category.valid?
      expect(category.errors[:name]).to be_present
    end
    
    it 'validates name uniqueness within company' do
      category1 = create(:category, company: company, name: 'Food')
      category2 = Resources::Category.new(company: company, name: 'Food')
      category2.valid?
      expect(category2.errors[:name]).to be_present
    end
  end
  
  describe 'associations' do
    it 'belongs to company' do
      category = create(:category, company: company)
      expect(category.company).to eq(company)
    end
    
    it 'has products' do
      category = create(:category, company: company)
      product = create(:product, company: company, category: category)
      expect(category.products).to include(product)
    end
  end
  
  end
end
