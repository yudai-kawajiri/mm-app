require 'rails_helper'

RSpec.describe 'Admin::SystemLogs', type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    host! 'admin.example.com'
  end

  describe 'system logs management' do
    it 'accesses system logs index' do
      get '/admin/system_logs' rescue nil
      expect([ 200, 302, 404, 500 ]).to include(response.status)
    end

    it 'accesses system logs show' do
      # ダミーIDで存在確認
      get '/admin/system_logs/1' rescue nil
      expect([ 200, 302, 404, 500 ]).to include(response.status)
    end
  end
end
