require 'rails_helper'

RSpec.describe "Categories", type: :request do
  let(:super_admin_user) { create(:user, :super_admin) }
  let(:general_user) { create(:user, :general) }
  let!(:category) { create(:category, user: admin_user) }

  describe 'GET /categories' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get resources_categories_path
        expect(response).to have_http_status(:success)
      end

      it '@categoriesにカテゴリ―を割り当てること' do
        get resources_categories_path
        expect(assigns(:categories)).to include(category)
      end

      it 'indexテンプレートを表示すること' do
        get resources_categories_path
        expect(response).to render_template(:index)
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get resources_categories_path, params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'category_typeパラメータでリクエストが成功すること' do
          get resources_categories_path, params: { category_type: 'material' }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get resources_categories_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /categories/new' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get new_resources_category_path
        expect(response).to have_http_status(:success)
      end

      it '@categoryに新しいカテゴリ―を割り当てること' do
        get new_resources_category_path
        expect(assigns(:category)).to be_a_new(Resources::Category)
      end

      it 'newテンプレートを表示すること' do
        get new_resources_category_path
        expect(response).to render_template(:new)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get new_resources_category_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /categories' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_category: {
              name: '新しいカテゴリ―',
              reading: "てすとかてごりー",
              category_type: 'material',
              description: 'テスト概要'
            }
          }
        end

        it 'カテゴリ―が作成されること' do
          expect {
            post resources_categories_path, params: valid_params
          }.to change(Resources::Category, :count).by(1)
        end

        it '作成したカテゴリ―詳細にリダイレクトされること' do
          post resources_categories_path, params: valid_params
          expect(response).to redirect_to(resources_category_url(Resources::Category.last))
        end

        it '成功メッセージが表示されること' do
          post resources_categories_path, params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_category: {
              name: '',
              category_type: 'material'
            }
          }
        end

        it 'カテゴリ―が作成されないこと' do
          expect {
            post resources_categories_path, params: invalid_params
          }.not_to change(Resources::Category, :count)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post resources_categories_path, params: { resources_category: { name: 'テスト' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /categories/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get resources_category_path(category)
        expect(response).to have_http_status(:success)
      end

      it '@categoryにカテゴリ―を割り当てること' do
        get resources_category_path(category)
        expect(assigns(:category)).to eq(category)
      end

      it 'showテンプレートを表示すること' do
        get resources_category_path(category)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get resources_category_path(category)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /categories/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get edit_resources_category_path(category)
        expect(response).to have_http_status(:success)
      end

      it '@categoryにカテゴリ―を割り当てること' do
        get edit_resources_category_path(category)
        expect(assigns(:category)).to eq(category)
      end

      it 'editテンプレートを表示すること' do
        get edit_resources_category_path(category)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get edit_resources_category_path(category)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /categories/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_category: {
              name: '更新されたカテゴリ―名',
              reading: 'こうしんされたかてごり―',
              description: '更新された概要'
            }
          }
        end

        let(:update_params) do
          {
            resources_category: {
              name: '更新されたカテゴリ―名',
              reading: 'こうしんされたかてごりーめい',
              category_type: 'product',
              description: '更新された説明'
            }
          }
        end

        it 'カテゴリ―が更新されること' do
          patch resources_category_path(category), params: update_params
          category.reload
          expect(category.name).to eq('更新されたカテゴリ―名')
        end

        it 'カテゴリ―詳細にリダイレクトされること' do
          patch resources_category_path(category), params: update_params
          expect(response).to redirect_to(resources_category_url(category))
        end

        it '成功メッセージが表示されること' do
          patch resources_category_path(category), params: update_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_category: {
              name: ''
            }
          }
        end

        it 'カテゴリ―が更新されないこと' do
          original_name = category.name
          patch resources_category_path(category), params: invalid_params
          category.reload
          expect(category.name).to eq(original_name)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch resources_category_path(category), params: { resources_category: { name: '更新' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /categories/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it 'カテゴリ―が削除されること' do
        category_to_delete = create(:category, user: admin_user)
        expect {
          delete resources_category_path(category_to_delete)
        }.to change(Resources::Category, :count).by(-1)
      end

      it 'カテゴリ―一覧にリダイレクトされること' do
        delete resources_category_path(category)
        expect(response).to redirect_to(resources_categories_url)
      end

      it '成功メッセージが表示されること' do
        delete resources_category_path(category)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete resources_category_path(category)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
