require 'rails_helper'

RSpec.describe ProductsHelper, type: :helper do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }

  describe 'helper inclusion' do
    it 'is included' do
      expect(helper.class.ancestors.map(&:to_s)).to include('ProductsHelper')
    end
  end
end
