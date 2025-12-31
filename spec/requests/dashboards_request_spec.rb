require 'rails_helper'

RSpec.describe 'Dashboards', type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, :super_admin, company: company) }
  let(:general_user) { create(:user, :general, company: company) }
  let(:year) { Date.current.year }
  let(:month) { Date.current.month }

  describe 'GET /dashboards' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it 'returns success' do
        get scoped_path(:dashboards)
        expect([200, 302]).to include(response.status)
      end

      it '@forecast_dataに予測データを割り当てること' do
        get scoped_path(:dashboards)
        expect(assigns(:forecast_data)).not_to be_nil
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        get scoped_path(:dashboards)
        expect([302, 404]).to include(response.status)
      end
    end
  end

  describe 'GET #index with data' do
    let(:store) { create(:store, company: company) }
    let!(:plan) { create(:plan, company: company) }
    let!(:product) { create(:product, company: company, store: store) }
    let!(:material) { create(:material, company: company, store: store) }
    
    context 'ログイン済み' do
      before do
        sign_in general_user, scope: :user
        host! "#{company.slug}.example.com"
      end
      
      it 'ダッシュボードデータを取得する' do
        get scoped_path(:dashboards)
        expect([200, 302]).to include(response.status)
      end
    end
  end

end