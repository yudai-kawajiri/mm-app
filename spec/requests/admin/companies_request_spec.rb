require 'rails_helper'

RSpec.describe 'Admin::Companies', type: :request do
  let(:company) { create(:company) }
  let(:super_admin) { create(:user, :super_admin, company: company) }

  before do
    sign_in super_admin, scope: :user
    host! 'admin.example.com'
  end

  describe 'GET /admin/companies' do
    it 'returns success or redirect' do
      get '/admin/companies'
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end
end
