require 'rails_helper'

RSpec.describe "Categories", type: :request do
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, :super_admin, company: company) }
  let(:general_user) { create(:user, :general, company: company) }
  let!(:category) { create(:category, user: super_admin_user) }

  describe 'GET /categories' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:resources_categories)
        expect(response).to have_http_status(:success)
      end

      it '@categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:resources_categories)
        expect(assigns(:categories)).to include(category)
      end

      it 'indexテンプレートを表示すること' do
        get scoped_path(:resources_categories)
        expect(response).to render_template(:index)
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get scoped_path(:resources_categories), params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'category_typeパラメータでリクエストが成功すること' do
          get scoped_path(:resources_categories), params: { category_type: 'material' }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:resources_categories)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'GET /categories/new' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:new_resources_category)
        expect(response).to have_http_status(:success)
      end

      it '@categoryに新しいカテゴリ―を割り当てること' do
        get scoped_path(:new_resources_category)
        expect(assigns(:category)).to be_a_new(Resources::Category)
      end

      it 'newテンプレートを表示すること' do
        get scoped_path(:new_resources_category)
        expect(response).to render_template(:new)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:new_resources_category)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'POST /categories' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

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
            post scoped_path(:resources_categories), params: valid_params
          }.to change(Resources::Category, :count).by(1)
        end

        it '作成したカテゴリ―詳細にリダイレクトされること' do
          post scoped_path(:resources_categories), params: valid_params
          expect(response).to redirect_to(scoped_path(:resources_category, id: Resources::Category.last.id))
        end

        it '成功メッセージが表示されること' do
          post scoped_path(:resources_categories), params: valid_params
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
            post scoped_path(:resources_categories), params: invalid_params
          }.not_to change(Resources::Category, :count)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post scoped_path(:resources_categories), params: { resources_category: { name: 'テスト' } }
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'GET /categories/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:resources_category, category)
        expect(response).to have_http_status(:success)
      end

      it '@categoryにカテゴリ―を割り当てること' do
        get scoped_path(:resources_category, category)
        expect(assigns(:category)).to eq(category)
      end

      it 'showテンプレートを表示すること' do
        get scoped_path(:resources_category, category)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:resources_category, category)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'GET /categories/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:edit_resources_category, category)
        expect(response).to have_http_status(:success)
      end

      it '@categoryにカテゴリ―を割り当てること' do
        get scoped_path(:edit_resources_category, category)
        expect(assigns(:category)).to eq(category)
      end

      it 'editテンプレートを表示すること' do
        get scoped_path(:edit_resources_category, category)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:edit_resources_category, category)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /categories/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

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
          patch scoped_path(:resources_category, category), params: update_params
          category.reload
          expect(category.name).to eq('更新されたカテゴリ―名')
        end

        it 'カテゴリ―詳細にリダイレクトされること' do
          patch scoped_path(:resources_category, category), params: update_params
          expect(response).to redirect_to(scoped_path(:resources_category, id: category.id))
        end

        it '成功メッセージが表示されること' do
          patch scoped_path(:resources_category, category), params: update_params
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
          patch scoped_path(:resources_category, category), params: invalid_params
          category.reload
          expect(category.name).to eq(original_name)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch scoped_path(:resources_category, category), params: { resources_category: { name: '更新' } }
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /categories/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it 'カテゴリ―が削除されること' do
        category_to_delete = create(:category, user: super_admin_user)
        expect {
          delete scoped_path(:resources_category, category_to_delete)
        }.to change(Resources::Category, :count).by(-1)
      end

      it 'カテゴリ―一覧にリダイレクトされること' do
        delete scoped_path(:resources_category, category)
        expect(response).to redirect_to(scoped_path(:resources_categories))
      end

      it '成功メッセージが表示されること' do
        delete scoped_path(:resources_category, category)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete scoped_path(:resources_category, category)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end
end
