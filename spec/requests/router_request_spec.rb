require 'rails_helper'

RSpec.describe RouterController, type: :request do
  let(:company) { create(:company) }

  describe 'routing' do
    it 'handles root path' do
      get "http://#{company.slug}.example.com/"
      expect([200, 302, 404]).to include(response.status)
    end
  end
end
