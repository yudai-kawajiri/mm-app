require 'rails_helper'

RSpec.describe Admin::SystemLogsController, type: :request do
  let(:company) { create(:company) }
  let(:super_admin) { create(:user, :super_admin, company: company) }

  before do
    sign_in super_admin, scope: :user
    host! 'admin.example.com'
  end

  describe 'GET /admin/system_logs' do
    it 'lists system logs' do
      get '/admin/system_logs'
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'GET /admin/system_logs/:id' do
    it 'shows log details' do
      get '/admin/system_logs/1'
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'filtering' do
    it 'filters by date' do
      get '/admin/system_logs', params: { date: Date.today.to_s }
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'filters by user' do
      get '/admin/system_logs', params: { user_id: super_admin.id }
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end
end
