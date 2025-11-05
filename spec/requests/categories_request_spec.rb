require 'rails_helper'

RSpec.describe "Categories", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:staff_user) { create(:user, :staff) }
  let!(:category) { create(:category, user: admin_user) }

  describe 'GET /categories' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get categories_path
        expect(response).to have_http_status(:success)
      end

      it '@categoriesにカテゴリを割り当てること' do
        get categories_path
        expect(assigns(:categories)).to include(category)
      end

      it 'indexテンプレートを表示すること' do
        get categories_path
        expect(response).to render_template(:index)
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get categories_path, params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'category_typeパラメータでリクエストが成功すること' do
          get categories_path, params: { category_type: 'material' }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get categories_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /categories/new' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get new_category_path
        expect(response).to have_http_status(:success)
      end

      it '@categoryに新しいカテゴリを割り当てること' do
        get new_category_path
        expect(assigns(:category)).to be_a_new(Category)
      end

      it 'newテンプレートを表示すること' do
        get new_category_path
        expect(response).to render_template(:new)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get new_category_path
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
            category: {
              name: '新しいカテゴリ',
              category_type: 'material',
              description: 'テスト説明'
            }
          }
        end

        it 'カテゴリが作成されること' do
          expect {
            post categories_path, params: valid_params
          }.to change(Category, :count).by(1)
        end

        it 'カテゴリ一覧にリダイレクトされること' do
          post categories_path, params: valid_params
          expect(response).to redirect_to(categories_url)
        end

        it '成功メッセージが表示されること' do
          post categories_path, params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            category: {
              name: '',
              category_type: 'material'
            }
          }
        end

        it 'カテゴリが作成されないこと' do
          expect {
            post categories_path, params: invalid_params
          }.not_to change(Category, :count)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post categories_path, params: { category: { name: 'テスト' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /categories/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get category_path(category)
        expect(response).to have_http_status(:success)
      end

      it '@categoryにカテゴリを割り当てること' do
        get category_path(category)
        expect(assigns(:category)).to eq(category)
      end

      it 'showテンプレートを表示すること' do
        get category_path(category)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get category_path(category)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /categories/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get edit_category_path(category)
        expect(response).to have_http_status(:success)
      end

      it '@categoryにカテゴリを割り当てること' do
        get edit_category_path(category)
        expect(assigns(:category)).to eq(category)
      end

      it 'editテンプレートを表示すること' do
        get edit_category_path(category)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get edit_category_path(category)
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
            category: {
              name: '更新されたカテゴリ名',
              description: '更新された説明'
            }
          }
        end

        it 'カテゴリが更新されること' do
          patch category_path(category), params: valid_params
          category.reload
          expect(category.name).to eq('更新されたカテゴリ名')
        end

        it 'カテゴリ一覧にリダイレクトされること' do
          patch category_path(category), params: valid_params
          expect(response).to redirect_to(categories_url)
        end

        it '成功メッセージが表示されること' do
          patch category_path(category), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            category: {
              name: ''
            }
          }
        end

        it 'カテゴリが更新されないこと' do
          original_name = category.name
          patch category_path(category), params: invalid_params
          category.reload
          expect(category.name).to eq(original_name)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch category_path(category), params: { category: { name: '更新' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /categories/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it 'カテゴリが削除されること' do
        category_to_delete = create(:category, user: admin_user)
        expect {
          delete category_path(category_to_delete)
        }.to change(Category, :count).by(-1)
      end

      it 'カテゴリ一覧にリダイレクトされること' do
        delete category_path(category)
        expect(response).to redirect_to(categories_url)
      end

      it '成功メッセージが表示されること' do
        delete category_path(category)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete category_path(category)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
