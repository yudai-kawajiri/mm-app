require 'rails_helper'

RSpec.describe Resources::Category, type: :model do
  let(:company) { create(:company) }

  describe '重要メソッド' do
    

    it 'has products association' do
      category = create(:category, company: company)
      expect(category).to respond_to(:products)
    end

    it 'belongs to company' do
      category = create(:category, company: company)
      expect(category.company).to eq(company)
    end
  end
end
