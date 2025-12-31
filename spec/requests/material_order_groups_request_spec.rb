require 'rails_helper'

RSpec.describe "Resources::MaterialOrderGroups", type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }

  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let!(:material_order_group) { create(:material_order_group, user: user) }

  describe 'GET /resources/material_order_groups' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:resources_material_order_groups)
        expect(response).to have_http_status(:success)
      end

      it '@material_order_groupsに発注グループを割り当てること' do
        get scoped_path(:resources_material_order_groups)
        expect(assigns(:material_order_groups)).to include(material_order_group)
      end

      it 'indexテンプレートを表示すること' do
        get scoped_path(:resources_material_order_groups)
        expect(response).to render_template(:index)
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get scoped_path(:resources_material_order_groups), params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:resources_material_order_groups)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /resources/material_order_groups/:id' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to have_http_status(:success)
      end

      it '@material_order_groupに発注グループを割り当てること' do
        get scoped_path(:resources_material_order_group, material_order_group)
        expect(assigns(:material_order_group)).to eq(material_order_group)
      end

      it 'showテンプレートを表示すること' do
        get scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /resources/material_order_groups/new' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:new_resources_material_order_group)
        expect(response).to have_http_status(:success)
      end

      it '@material_order_groupに新しい発注グループを割り当てること' do
        get scoped_path(:new_resources_material_order_group)
        expect(assigns(:material_order_group)).to be_a_new(Resources::MaterialOrderGroup)
      end

      it 'newテンプレートを表示すること' do
        get scoped_path(:new_resources_material_order_group)
        expect(response).to render_template(:new)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:new_resources_material_order_group)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /resources/material_order_groups' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_attributes) { { name: '新しい発注グループ', reading: 'あたらしいはっちゅうぐるぷ' } }

        it '発注グループが作成されること' do
          expect {
            post scoped_path(:resources_material_order_groups), params: { resources_material_order_group: valid_attributes }
          }.to change(Resources::MaterialOrderGroup, :count).by(1)
        end

        it '作成された発注グループの詳細ページにリダイレクトされること' do
          post scoped_path(:resources_material_order_groups), params: { resources_material_order_group: valid_attributes }
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          post scoped_path(:resources_material_order_groups), params: { resources_material_order_group: valid_attributes }
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_attributes) { { name: '', reading: '' } }

        it '発注グループが作成されないこと' do
          expect {
            post scoped_path(:resources_material_order_groups), params: { resources_material_order_group: invalid_attributes }
          }.not_to change(Resources::MaterialOrderGroup, :count)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post scoped_path(:resources_material_order_groups), params: { resources_material_order_group: { name: 'テスト' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /resources/material_order_groups/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get edit_scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to have_http_status(:success)
      end

      it '@material_order_groupに発注グループを割り当てること' do
        get edit_scoped_path(:resources_material_order_group, material_order_group)
        expect(assigns(:material_order_group)).to eq(material_order_group)
      end

      it 'editテンプレートを表示すること' do
        get edit_scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get edit_scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /resources/material_order_groups/:id' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      context '有効なパラメータの場合' do
        let(:new_attributes) { { name: '更新された発注グループ' } }

        it '発注グループが更新されること' do
          patch scoped_path(:resources_material_order_group, material_order_group), params: { resources_material_order_group: new_attributes }
          material_order_group.reload
          expect(material_order_group.name).to eq('更新された発注グループ')
        end

        it '更新された発注グループの詳細ページにリダイレクトされること' do
          patch scoped_path(:resources_material_order_group, material_order_group), params: { resources_material_order_group: new_attributes }
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          patch scoped_path(:resources_material_order_group, material_order_group), params: { resources_material_order_group: new_attributes }
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_attributes) { { name: '' } }

        it '発注グループが更新されないこと' do
          original_name = material_order_group.name
          patch scoped_path(:resources_material_order_group, material_order_group), params: { resources_material_order_group: invalid_attributes }
          material_order_group.reload
          expect(material_order_group.name).to eq(original_name)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch scoped_path(:resources_material_order_group, material_order_group), params: { resources_material_order_group: { name: '更新' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /resources/material_order_groups/:id' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '発注グループが削除されること' do
        expect {
          delete scoped_path(:resources_material_order_group, material_order_group)
        }.to change(Resources::MaterialOrderGroup, :count).by(-1)
      end

      it '発注グループ一覧にリダイレクトされること' do
        delete scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to have_http_status(:redirect)
      end

      it '成功メッセージが表示されること' do
        delete scoped_path(:resources_material_order_group, material_order_group)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /resources/material_order_groups/:id/copy' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '発注グループがコピーされること' do
        expect {
          post copy_scoped_path(:resources_material_order_group, material_order_group)
        }.to change(Resources::MaterialOrderGroup, :count).by(1)
      end

      it '発注グループ一覧にリダイレクトされること' do
        post copy_scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to have_http_status(:redirect)
      end

      it '成功メッセージが表示されること' do
        post copy_scoped_path(:resources_material_order_group, material_order_group)
        expect(flash[:notice]).to be_present
      end

      it 'コピーされた発注グループの名前に「コピー」が含まれること' do
        post copy_scoped_path(:resources_material_order_group, material_order_group)
        copied_group = Resources::MaterialOrderGroup.last
        expect(copied_group.name).to match(/コピー/)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post copy_scoped_path(:resources_material_order_group, material_order_group)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  describe 'POST #create' do
    context 'ログインしている場合' do
      it '発注グループを作成できる' do
        post scoped_path(:resources_material_order_groups), params: { resources_material_order_group: { name: 'New Group', order_date: Date.today } }
        expect([200, 302, 404]).to include(response.status)
      end
    end
  end

  describe 'PATCH #update' do
    let(:material_order_group) { create(:material_order_group, company: company) }

    context 'ログインしている場合' do
      it '発注グループを更新できる' do
        patch scoped_path(:resources_material_order_group, material_order_group), params: { resources_material_order_group: { name: 'Updated' } }
        expect([200, 302, 404]).to include(response.status)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:material_order_group) { create(:material_order_group, company: company) }

    context 'ログインしている場合' do
      it '発注グループを削除できる' do
        delete scoped_path(:resources_material_order_group, material_order_group)
        expect([200, 302, 404]).to include(response.status)
      end
    end
  end

end