require 'rails_helper'

RSpec.describe ApplicationRequestsHelper, type: :helper do
  describe 'helper methods' do
    it 'is included in helper' do
      expect(helper.class.ancestors).to include(ApplicationRequestsHelper)
    end
  end
end
