require 'rails_helper'

RSpec.describe PlansHelper, type: :helper do
  let(:company) { create(:company) }
  let(:plan) { create(:plan, company: company) }
  
  describe 'helper inclusion' do
    it 'is included' do
      expect(helper.class.ancestors.map(&:to_s)).to include('PlansHelper')
    end
  end
end
