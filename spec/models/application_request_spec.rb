require 'rails_helper'

RSpec.describe ApplicationRequest, type: :model do
  describe 'basic model' do
    it 'can be instantiated' do
      request = ApplicationRequest.new
      expect(request).to be_a(ApplicationRequest)
    end
  end
end
