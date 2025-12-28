require 'rails_helper'

RSpec.describe Store, type: :model do
  let(:company) { create(:company) }
  
  describe 'validations' do
    it 'requires name' do
      store = Store.new(name: nil, company: company)
      store.valid?
      expect(store.errors[:name]).to be_present
    end
    
    it 'requires company' do
      store = Store.new(name: 'Test Store', company: nil)
      store.valid?
      expect(store.errors[:company]).to be_present
    end
    
    it 'has users' do
      store = create(:store, company: company)
      user = create(:user, company: company, store: store)
      expect(store.users).to include(user)
    end
  end
  
  describe 'associations' do
    it 'belongs to company' do
      store = create(:store, company: company)
      expect(store.company).to eq(company)
    end
    
    it 'has materials' do
      store = create(:store, company: company)
      material = create(:material, company: company, store: store)
      expect(store.materials).to include(material)
    end
    
    it 'has products' do
      store = create(:store, company: company)
      product = create(:product, company: company, store: store)
      expect(store.products).to include(product)
    end
  end
end
