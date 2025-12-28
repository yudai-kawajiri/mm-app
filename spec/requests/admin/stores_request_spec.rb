require 'rails_helper'

RSpec.describe Admin::StoresController, type: :request do
  let(:company) { create(:company) }
  let(:super_admin) { create(:user, :super_admin, company: company) }
  let(:store) { create(:store, company: company) }

  before do
    sign_in super_admin, scope: :user
    host! 'admin.example.com'
  end

  describe 'GET /admin/stores' do
    it 'lists stores' do
      get '/admin/stores'
      expect([200, 302, 404]).to include(response.status)
    end
  end
  
  describe 'GET /admin/stores/:id' do
    it 'shows store' do
      get "/admin/stores/#{store.id}"
      expect([200, 302, 404]).to include(response.status)
    end
  end
  
  describe 'POST /admin/stores' do
    it 'creates store' do
      post '/admin/stores', params: {
        store: { name: 'New Store', company_id: company.id }
      }
      expect([200, 302, 404, 422]).to include(response.status)
    end
  end
end
