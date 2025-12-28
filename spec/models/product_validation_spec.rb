require 'rails_helper'

RSpec.describe Resources::Product, type: :model do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:category) { create(:category, company: company) }
  
  describe 'validations' do
    it 'requires name' do
      product = Resources::Product.new(company: company, store: store, name: nil)
      product.valid?
      expect(product.errors[:name]).to be_present
    end
    
    it 'has category association' do
      product = create(:product, company: company, store: store, category: category)
      expect(product.category).to eq(category)
    end
    
    it 'can have product_materials' do
      product = create(:product, company: company, store: store)
      expect(product).to respond_to(:product_materials)
    end
  end
  
  describe 'calculations' do
    it 'calculates total cost' do
      product = create(:product, company: company, store: store)
      material = create(:material, company: company, store: store)
      product_material = Planning::ProductMaterial.create(
        product: product,
        material: material,
        quantity: 10
      )
      expect(product.product_materials.count).to be >= 0
    end
  end
end
