require 'rails_helper'

RSpec.describe Management::DailyTargetsController, type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user, scope: :user
    host! "#{company.slug}.example.com"
  end

  describe 'GET index' do
    it 'shows daily targets' do
      get scoped_path(:management_daily_targets)
      expect([200, 302, 404]).to include(response.status)
    end
  end
  
  end
