require 'rails_helper'

RSpec.describe Resources::Material, type: :model do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:unit) { create(:unit, company: company) }

  describe '重要メソッド' do
    it 'belongs to company' do
      material = create(:material, company: company, store: store)
      expect(material.company).to eq(company)
    end

    it 'has name' do
      material = create(:material, company: company, store: store)
      expect(material.name).to be_present
    end
  end
end
