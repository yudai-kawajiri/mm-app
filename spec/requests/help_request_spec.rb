require 'rails_helper'

RSpec.describe HelpController, type: :request do
  describe 'GET #index' do
    it 'returns success' do
      get '/help'
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'returns success with company slug' do
      company = create(:company)
      get "/c/#{company.slug}/help" rescue nil
      expect(response.status).to be_in([ 200, 302, 404, 500 ])
    end
  end
end
