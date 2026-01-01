require 'rails_helper'

RSpec.describe AdminRequest, type: :model do
  describe 'basic model' do
    it 'can be instantiated' do
      request = AdminRequest.new
      expect(request).to be_a(AdminRequest)
    end
  end
end
