require 'rails_helper'

RSpec.describe 'Admin権限テスト', type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, role: :super_admin, company: company) }
  let(:general_user) { create(:user, role: :general, company: company) }
  let(:target_user) { create(:user, role: :general, company: company) }

  describe 'Admin::UsersController' do
    describe 'GET /admin/users' do
      context 'adminユーザーの場合' do
        it 'ユーザー一覧にアクセスできる' do
          sign_in super_admin_user, scope: :user
          get scoped_path(:admin_users)
          expect(response).to have_http_status(:success)
        end
      end

      context 'staffユーザーの場合' do
        it 'ユーザー一覧にアクセスできない' do
          login_as(general_user, scope: :user)
          get scoped_path(:admin_users)
          expect(response).to have_http_status(:redirect)
          expect(response).to have_http_status(:redirect)
        end
      end

      context '未ログインユーザーの場合' do
        it 'ログインページにリダイレクトされる' do
        get admin_users_path
        expect(response).to have_http_status(:redirect)
      end
      end
    end

    describe 'DELETE /admin/users/:id' do
      let!(:target_user) { create(:user, role: :general) }

      context 'adminユーザーの場合' do
        it '他のユーザーを削除できる' do
        delete admin_user_path(user_to_delete)
        expect(response).to have_http_status(:redirect)
      end
      end

      context 'staffユーザーの場合' do
        it '他のユーザーを削除できない' do
          login_as(general_user, scope: :user)
          expect {
            delete scoped_path(:admin_user, target_user)
          }.not_to change(User, :count)
          expect(response).to have_http_status(:redirect)
          expect(response).to have_http_status(:redirect)
        end
      end
    end

  describe 'Admin::SystemLogsController' do
    describe 'GET /admin/system_logs' do
      context 'adminユーザーの場合' do
        it 'システムログにアクセスできる' do
          sign_in super_admin_user, scope: :user
          get scoped_path(:admin_system_logs)
          expect(response).to have_http_status(:success)
        end
      end

      context 'staffユーザーの場合' do
        it 'システムログにアクセスできない' do
          login_as(general_user, scope: :user)
          get scoped_path(:admin_system_logs)
          expect(response).to have_http_status(:redirect)
          expect(response).to have_http_status(:redirect))
        end
      end
    end
  end

  describe 'Role enum' do
    it 'staffロールが正しく設定される' do
      user = create(:user, role: :general)
      expect(user.general?).to be true
      expect(user.super_admin?).to be false
    end

    it 'adminロールが正しく設定される' do
      user = create(:user, role: :super_admin)
      expect(user.super_admin?).to be true
      expect(user.general?).to be false
    end
  end
end
