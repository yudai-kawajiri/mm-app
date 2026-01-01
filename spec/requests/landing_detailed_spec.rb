require 'rails_helper'

RSpec.describe LandingController, type: :request do
  describe 'GET /' do
    it 'shows landing page' do
      get '/'
      expect([ 200, 302 ]).to include(response.status)
    end

    it 'renders for different subdomains' do
      company = create(:company)
      host! "#{company.slug}.example.com"
      get '/'
      expect([ 200, 302 ]).to include(response.status)
    end
  end
end
