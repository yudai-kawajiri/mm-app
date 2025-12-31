require 'rails_helper'

RSpec.describe 'Admin::SystemLogs', type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, :super_admin, company: company) }
  let(:admin_user) { super_admin_user }
  let(:general_user) { create(:user, :general, company: company) }

  describe 'GET /admin/system_logs' do
    context '管理者でログインしている場合' do
      before { sign_in super_admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:admin_system_logs)
        expect(response).to have_http_status(:success)
      end

      it '@versionsにPaperTrailのバージョンを割り当てること' do
        get scoped_path(:admin_system_logs)
        expect(assigns(:versions)).not_to be_nil
      end

      it 'indexテンプレートを表示すること' do
        get scoped_path(:admin_system_logs)
        expect(response).to render_template(:index)
      end

      context 'item_typeでフィルタする場合' do
        it '指定したitem_typeパラメータでリクエストが成功すること' do
          get scoped_path(:admin_system_logs), params: { item_type: 'User' }
          expect(response).to have_http_status(:success)
          expect(assigns(:versions)).not_to be_nil
        end
      end

      context 'whodunnitでフィルタする場合' do
        it '指定したwhodunnitパラメータでリクエストが成功すること' do
          get scoped_path(:admin_system_logs), params: { whodunnit: admin_user.id.to_s }
          expect(response).to have_http_status(:success)
          expect(assigns(:versions)).not_to be_nil
        end
      end

      context '日付でフィルタする場合' do
        it 'date_fromパラメータでリクエストが成功すること' do
          get scoped_path(:admin_system_logs), params: { date_from: Date.today.to_s }
          expect(response).to have_http_status(:success)
          expect(assigns(:versions)).not_to be_nil
        end

        it 'date_toパラメータでリクエストが成功すること' do
          get scoped_path(:admin_system_logs), params: { date_to: Date.today.to_s }
          expect(response).to have_http_status(:success)
          expect(assigns(:versions)).not_to be_nil
        end
      end

      it '@model_typesに全てのモデルタイプを割り当てること' do
        get scoped_path(:admin_system_logs)
        expect(assigns(:model_types)).to be_an(Array)
      end

      it '@usersに全ユーザーを割り当てること' do
        get scoped_path(:admin_system_logs)
        expect(assigns(:users)).to include(admin_user)
      end
    end

    context 'スタッフでログインしている場合' do
      before { sign_in general_user, scope: :user }

      it 'リダイレクトされること' do
        get scoped_path(:admin_system_logs)
        expect([302, 404]).to include(response.status)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:admin_system_logs)
        expect([302, 404]).to include(response.status)
      end
      end
    end
  end
