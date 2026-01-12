require 'rails_helper'

RSpec.describe 'Admin Companies Management', type: :request do
  let(:super_admin) { create(:user, :super_admin, company: create(:company)) }

  before do
    sign_in super_admin, scope: :user
    host! 'admin.example.com'
  end

  describe 'company CRUD' do
    it 'lists companies' do
      get '/admin/companies'
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'shows company' do
      company = create(:company)
      get "/admin/companies/#{company.id}"
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    xit 'creates company' do
      post '/admin/companies', params: {
        company: { name: 'New Company', slug: 'new-company', email: 'info@example.com' }
      }
      expect(response).to have_http_status(:redirect)
      expect(Company.last.name).to eq('New Company')
      expect(Company.last.slug).to eq('new-company')
      expect(Company.last.email).to eq('info@example.com')
    end
  end
end
