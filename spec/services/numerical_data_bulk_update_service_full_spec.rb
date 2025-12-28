require 'rails_helper'

RSpec.describe NumericalDataBulkUpdateService, type: :service do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }

  describe 'service exists' do
    it 'is defined as a constant' do
      expect(defined?(NumericalDataBulkUpdateService)).to eq('constant')
    end

    it 'is a class' do
  expect(NumericalDataBulkUpdateService).to be_a(Class)
end
  end
end
