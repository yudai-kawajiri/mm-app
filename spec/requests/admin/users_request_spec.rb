require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, :super_admin, approved: true, company: company) }
  let(:general_user) { create(:user, :general, company: company) }
  let(:target_user) { create(:user, :general, company: company) }

  describe 'GET /admin/users' do
    context '管理者でログインしている場合' do
      before { sign_in super_admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:admin_users)
        expect(response).to have_http_status(:success)
      end

      it '@usersに全ユーザーを割り当てること' do
        user1 = create(:user, :general, approved: true, company: company)
        user2 = create(:user, :general, approved: true, company: company)
        get scoped_path(:admin_users)
        expect(assigns(:users)).to include(user1, user2, super_admin_user)
      end

      it 'indexテンプレートを表示すること' do
        get scoped_path(:admin_users)
        expect(response).to render_template(:index)
      end
    end

    context 'スタッフでログインしている場合' do
      before { sign_in general_user, scope: :user }

      it 'リダイレクトされること' do
        get scoped_path(:admin_users)
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:admin_users)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /admin/users/:id' do
    let!(:target_user) { create(:user, :general, company: company) }

    context '管理者でログインしている場合' do
      before { sign_in super_admin_user, scope: :user }

      it 'ユーザーが削除されること' do
        expect {
          delete scoped_path(:admin_user, target_user)
        }.to change(User, :count).by(-1)
      end

      it 'ユーザー一覧にリダイレクトされること' do
        delete scoped_path(:admin_user, target_user)
        expect(response).to redirect_to(scoped_path(:admin_users))
      end

      it '成功メッセージが表示されること' do
        delete scoped_path(:admin_user, target_user)
        expect(flash[:notice]).to be_present
      end

      it '自分自身は削除できないこと' do
        expect {
          delete scoped_path(:admin_user, super_admin_user)
        }.not_to change(User, :count)
      end

      it '自分自身を削除しようとするとエラーメッセージが表示されること' do
        delete scoped_path(:admin_user, super_admin_user)
        expect(flash[:alert]).to be_present
      end
    end

    context 'スタッフでログインしている場合' do
      before { sign_in general_user, scope: :user }

      it 'ユーザーが削除されないこと' do
        expect {
          delete scoped_path(:admin_user, target_user)
        }.not_to change(User, :count)
      end

      it 'リダイレクトされること' do
        delete scoped_path(:admin_user, target_user)
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
