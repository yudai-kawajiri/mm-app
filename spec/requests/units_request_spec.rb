require 'rails_helper'

RSpec.describe "Units", type: :request do
  let(:super_admin_user) { create(:user, :super_admin) }
  let(:general_user) { create(:user, :general) }
  let!(:unit) { create(:unit, user: admin_user) }

  describe 'GET /units' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get resources_units_path
        expect(response).to have_http_status(:success)
      end

      it '@unitsに単位を割り当てること' do
        get resources_units_path
        expect(assigns(:units)).to include(unit)
      end

      it 'indexテンプレートを表示すること' do
        get resources_units_path
        expect(response).to render_template(:index)
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get resources_units_path, params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'categoryパラメータでリクエストが成功すること' do
          get resources_units_path, params: { category: 'production' }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get resources_units_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /units/new' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get new_resources_unit_path
        expect(response).to have_http_status(:success)
      end

      it '@unitに新しい単位を割り当てること' do
        get new_resources_unit_path
        expect(assigns(:unit)).to be_a_new(Resources::Unit)
      end

      it 'newテンプレートを表示すること' do
        get new_resources_unit_path
        expect(response).to render_template(:new)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get new_resources_unit_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /units' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_unit: {
              name: '新しい単位',
              reading: 'あたらしいたんい',
              category: 'production',
              description: 'テスト概要'
            }
          }
        end

        it '単位が作成されること' do
          expect {
            post resources_units_path, params: valid_params
          }.to change(Resources::Unit, :count).by(1)
        end

        it '単位一覧にリダイレクトされること' do
          post resources_units_path, params: valid_params
          expect(response).to redirect_to(resources_unit_path(Resources::Unit.last))
        end

        it '成功メッセージが表示されること' do
          post resources_units_path, params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_unit: {
              name: '',
              category: 'production'
            }
          }
        end

        it '単位が作成されないこと' do
          expect {
            post resources_units_path, params: invalid_params
          }.not_to change(Resources::Unit, :count)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post resources_units_path, params: { resources_unit: { name: 'テスト' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /units/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get resources_unit_path(unit)
        expect(response).to have_http_status(:success)
      end

      it '@unitに単位を割り当てること' do
        get resources_unit_path(unit)
        expect(assigns(:unit)).to eq(unit)
      end

      it 'showテンプレートを表示すること' do
        get resources_unit_path(unit)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get resources_unit_path(unit)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /units/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get edit_resources_unit_path(unit)
        expect(response).to have_http_status(:success)
      end

      it '@unitに単位を割り当てること' do
        get edit_resources_unit_path(unit)
        expect(assigns(:unit)).to eq(unit)
      end

      it 'editテンプレートを表示すること' do
        get edit_resources_unit_path(unit)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get edit_resources_unit_path(unit)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /units/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_unit: {
              name: '更新された単位名',
              description: '更新された概要'
            }
          }
        end

        it '単位が更新されること' do
          patch resources_unit_path(unit), params: valid_params
          unit.reload
          expect(unit.name).to eq('更新された単位名')
        end

        it '単位一覧にリダイレクトされること' do
          patch resources_unit_path(unit), params: valid_params
          expect(response).to redirect_to(resources_unit_path(unit))
        end

        it '成功メッセージが表示されること' do
          patch resources_unit_path(unit), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_unit: {
              name: ''
            }
          }
        end

        it '単位が更新されないこと' do
          original_name = unit.name
          patch resources_unit_path(unit), params: invalid_params
          unit.reload
          expect(unit.name).to eq(original_name)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch resources_unit_path(unit), params: { resources_unit: { name: '更新' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /units/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '単位が削除されること' do
        unit_to_delete = create(:unit, user: admin_user)
        expect {
          delete resources_unit_path(unit_to_delete)
        }.to change(Resources::Unit, :count).by(-1)
      end

      it '単位一覧にリダイレクトされること' do
        delete resources_unit_path(unit)
        expect(response).to redirect_to(resources_units_url)
      end

      it '成功メッセージが表示されること' do
        delete resources_unit_path(unit)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete resources_unit_path(unit)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
