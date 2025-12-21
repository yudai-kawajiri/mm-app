require 'rails_helper'

RSpec.describe 'Admin権限テスト', type: :request do
  let(:super_admin_user) { create(:user, role: :super_admin) }
  let(:general_user) { create(:user, role: :general) }

  describe 'Admin::UsersController' do
    describe 'GET /admin/users' do
      context 'adminユーザーの場合' do
        it 'ユーザー一覧にアクセスできる' do
          sign_in super_admin_user, scope: :user
          get admin_users_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'staffユーザーの場合' do
        it 'ユーザー一覧にアクセスできない' do
          sign_in general_user, scope: :user
          get admin_users_path
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(root_path)
        end
      end

      context '未ログインユーザーの場合' do
        it 'ログインページにリダイレクトされる' do
          get admin_users_path
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    describe 'DELETE /admin/users/:id' do
      let!(:target_user) { create(:user, role: :general) }

      context 'adminユーザーの場合' do
        it '他のユーザーを削除できる' do
          sign_in super_admin_user, scope: :user
          expect {
            delete admin_user_path(target_user)
          }.to change(User, :count).by(-1)
          expect(response).to have_http_status(:redirect)
        end
      end

      context 'staffユーザーの場合' do
        it '他のユーザーを削除できない' do
          sign_in general_user, scope: :user
          expect {
            delete admin_user_path(target_user)
          }.not_to change(User, :count)
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe 'Admin::SystemLogsController' do
    describe 'GET /admin/system_logs' do
      context 'adminユーザーの場合' do
        it 'システムログにアクセスできる' do
          sign_in super_admin_user, scope: :user
          get admin_system_logs_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'staffユーザーの場合' do
        it 'システムログにアクセスできない' do
          sign_in general_user, scope: :user
          get admin_system_logs_path
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(root_path)
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
