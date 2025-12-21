require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:super_admin_user) { create(:user, :super_admin, approved: true) }
  let(:general_user) { create(:user, :general) }

  describe 'GET /admin/users' do
    context '管理者でログインしている場合' do
      before { sign_in super_admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it '@usersに全ユーザーを割り当てること' do
        user1 = create(:user, approved: true)
        user2 = create(:user, approved: true)
        get admin_users_path
        expect(assigns(:users)).to include(user1, user2, super_admin_user)
      end

      it 'indexテンプレートを表示すること' do
        get admin_users_path
        expect(response).to render_template(:index)
      end
    end

    context 'スタッフでログインしている場合' do
      before { sign_in general_user, scope: :user }

      it 'リダイレクトされること' do
        get admin_users_path
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /admin/users/:id' do
    let!(:target_user) { create(:user) }

    context '管理者でログインしている場合' do
      before { sign_in super_admin_user, scope: :user }

      it 'ユーザーが削除されること' do
        expect {
          delete admin_user_path(target_user)
        }.to change(User, :count).by(-1)
      end

      it 'ユーザー一覧にリダイレクトされること' do
        delete admin_user_path(target_user)
        expect(response).to redirect_to(admin_users_path)
      end

      it '成功メッセージが表示されること' do
        delete admin_user_path(target_user)
        expect(flash[:notice]).to be_present
      end

      it '自分自身は削除できないこと' do
        expect {
          delete admin_user_path(super_admin_user)
        }.not_to change(User, :count)
      end

      it '自分自身を削除しようとするとエラーメッセージが表示されること' do
        delete admin_user_path(super_admin_user)
        expect(flash[:alert]).to be_present
      end
    end

    context 'スタッフでログインしている場合' do
      before { sign_in general_user, scope: :user }

      it 'ユーザーが削除されないこと' do
        expect {
          delete admin_user_path(target_user)
        }.not_to change(User, :count)
      end

      it 'リダイレクトされること' do
        delete admin_user_path(target_user)
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
