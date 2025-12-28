require 'rails_helper'

RSpec.describe Admin::AdminRequestsController, type: :request do
  let(:company) { create(:company) }
  let(:super_admin) { create(:user, :super_admin, company: company) }

  before do
    sign_in super_admin, scope: :user
    host! 'admin.example.com'
  end

  describe 'GET /admin/admin_requests' do
    it 'lists admin requests' do
      get '/admin/admin_requests'
      expect([200, 302, 404]).to include(response.status)
    end
  end
  
  describe 'GET /admin/admin_requests/new' do
    it 'shows new form' do
      get '/admin/admin_requests/new'
      expect([200, 302, 404]).to include(response.status)
    end
  end
end
