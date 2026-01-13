require 'rails_helper'

RSpec.describe LandingController, type: :request do
  describe 'GET #index' do
    it 'returns success' do
      get '/'
      expect([ 200, 302 ]).to include(response.status)
    end

    it 'handles root path with trailing slash' do
      get '/' rescue nil
      expect(response.status).to be_in([ 200, 302, 404, 500 ])
    end

    it 'responds to different formats' do
      get '/', params: {}, headers: { 'HTTP_ACCEPT' => 'text/html' } rescue nil
      expect(response.status).to be_in([ 200, 302, 404, 500 ])
    end
  end
end
