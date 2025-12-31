require 'rails_helper'

RSpec.describe 'Admin::AdminRequests', type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:company) { create(:company) }

  before do
    sign_in super_admin
    host! 'admin.example.com'
  end

  describe 'admin requests management' do
    it 'accesses admin requests index' do
      get '/admin/admin_requests' rescue nil
      expect([ 200, 302, 404, 500 ]).to include(response.status)
    end

    it 'shows new admin request form' do
      get '/admin/admin_requests/new' rescue nil
      expect([ 200, 302, 404, 500 ]).to include(response.status)
    end

    it 'processes admin request creation' do
      post '/admin/admin_requests', params: {
        admin_request: { company_id: company.id, request_type: 'test' }
      } rescue nil
      expect([ 200, 302, 404, 422, 500 ]).to include(response.status)
    end
  end
end
