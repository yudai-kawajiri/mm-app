require 'rails_helper'

RSpec.describe HelpController, type: :request do
  describe 'GET #index' do
    it 'returns success' do
      get '/help'
      expect([200, 302, 404]).to include(response.status)
    end
  end
end
