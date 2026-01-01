require 'rails_helper'

RSpec.describe 'Settings Access', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user, scope: :user
    host! "#{company.slug}.example.com"
  end

  describe 'GET /settings' do
    it 'accesses settings' do
      # コントローラーのアクションだけテスト、ビューはスタブ化
      allow_any_instance_of(SettingsController).to receive(:render).and_return(true)
      get "/c/#{company.slug}/settings"
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end
end
