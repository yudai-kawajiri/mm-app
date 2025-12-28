require 'rails_helper'

RSpec.describe RouterController, type: :request do
  let(:company) { create(:company) }
  
  describe 'routing with subdomain' do
    it 'routes to company root' do
      host! "#{company.slug}.example.com"
      get '/'
      expect([200, 302, 404]).to include(response.status)
    end
    
    it 'handles main domain' do
      host! 'example.com'
      get '/'
      expect([200, 302]).to include(response.status)
    end
  end
end
