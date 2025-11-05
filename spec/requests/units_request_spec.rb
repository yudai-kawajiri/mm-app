require 'rails_helper'

RSpec.describe "Units", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:staff_user) { create(:user, :staff) }
  let!(:unit) { create(:unit, user: admin_user) }

  describe 'GET /units' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get units_path
        expect(response).to have_http_status(:success)
      end

      it '@unitsに単位を割り当てること' do
        get units_path
        expect(assigns(:units)).to include(unit)
      end

      it 'indexテンプレートを表示すること' do
        get units_path
        expect(response).to render_template(:index)
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get units_path, params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'categoryパラメータでリクエストが成功すること' do
          get units_path, params: { category: 'production' }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get units_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /units/new' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get new_unit_path
        expect(response).to have_http_status(:success)
      end

      it '@unitに新しい単位を割り当てること' do
        get new_unit_path
        expect(assigns(:unit)).to be_a_new(Unit)
      end

      it 'newテンプレートを表示すること' do
        get new_unit_path
        expect(response).to render_template(:new)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get new_unit_path
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
            unit: {
              name: '新しい単位',
              category: 'production',
              description: 'テスト説明'
            }
          }
        end

        it '単位が作成されること' do
          expect {
            post units_path, params: valid_params
          }.to change(Unit, :count).by(1)
        end

        it '単位一覧にリダイレクトされること' do
          post units_path, params: valid_params
          expect(response).to redirect_to(units_url)
        end

        it '成功メッセージが表示されること' do
          post units_path, params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            unit: {
              name: '',
              category: 'production'
            }
          }
        end

        it '単位が作成されないこと' do
          expect {
            post units_path, params: invalid_params
          }.not_to change(Unit, :count)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post units_path, params: { unit: { name: 'テスト' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /units/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get unit_path(unit)
        expect(response).to have_http_status(:success)
      end

      it '@unitに単位を割り当てること' do
        get unit_path(unit)
        expect(assigns(:unit)).to eq(unit)
      end

      it 'showテンプレートを表示すること' do
        get unit_path(unit)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get unit_path(unit)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /units/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get edit_unit_path(unit)
        expect(response).to have_http_status(:success)
      end

      it '@unitに単位を割り当てること' do
        get edit_unit_path(unit)
        expect(assigns(:unit)).to eq(unit)
      end

      it 'editテンプレートを表示すること' do
        get edit_unit_path(unit)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get edit_unit_path(unit)
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
            unit: {
              name: '更新された単位名',
              description: '更新された説明'
            }
          }
        end

        it '単位が更新されること' do
          patch unit_path(unit), params: valid_params
          unit.reload
          expect(unit.name).to eq('更新された単位名')
        end

        it '単位一覧にリダイレクトされること' do
          patch unit_path(unit), params: valid_params
          expect(response).to redirect_to(units_url)
        end

        it '成功メッセージが表示されること' do
          patch unit_path(unit), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            unit: {
              name: ''
            }
          }
        end

        it '単位が更新されないこと' do
          original_name = unit.name
          patch unit_path(unit), params: invalid_params
          unit.reload
          expect(unit.name).to eq(original_name)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch unit_path(unit), params: { unit: { name: '更新' } }
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
          delete unit_path(unit_to_delete)
        }.to change(Unit, :count).by(-1)
      end

      it '単位一覧にリダイレクトされること' do
        delete unit_path(unit)
        expect(response).to redirect_to(units_url)
      end

      it '成功メッセージが表示されること' do
        delete unit_path(unit)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete unit_path(unit)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
