require 'rails_helper'

RSpec.describe Store, type: :model do
  describe 'validations' do
    let(:company) { create(:company) }

    it 'requires name' do
      store = Store.new(name: nil, company: company)
      store.valid?
      expect(store.errors[:name]).to be_present
    end
  end

  describe 'associations' do
    it 'belongs to company' do
      store = create(:store)
      expect(store.company).to be_a(Company)
    end
  end
end
