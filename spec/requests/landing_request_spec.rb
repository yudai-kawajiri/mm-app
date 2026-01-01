require 'rails_helper'

RSpec.describe LandingController, type: :request do
  describe 'GET #index' do
    it 'returns success' do
      get '/'
      expect([ 200, 302 ]).to include(response.status)
    end
  end
end
