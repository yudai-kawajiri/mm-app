require 'rails_helper'

RSpec.describe Resources::Product, type: :model do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:category) { create(:category, company: company) }

  describe '重要メソッド' do
    it 'can be instantiated' do
    product = Resources::Product.new(
      company: company,
      store: store,
      category: category,
      name: 'Test Product'
    )
    expect(product).to be_a(Resources::Product)
  end

    it 'belongs to company' do
      product = create(:product, company: company, store: store, category: category)
      expect(product.company).to eq(company)
    end

    it 'has name' do
      product = create(:product, company: company, store: store, category: category)
      expect(product.name).to be_present
    end
  end
end
