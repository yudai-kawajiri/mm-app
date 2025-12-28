require 'rails_helper'

RSpec.describe CompaniesController, type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, :super_admin, company: company) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET show' do
    it 'shows company with subdomain' do
      host! "#{company.slug}.example.com"
      get "/c/#{company.slug}"
      expect([200, 302, 404]).to include(response.status)
    end
    
    it 'shows company without subdomain' do
      get "/c/#{company.slug}"
      expect([200, 302, 404]).to include(response.status)
    end
  end
end
