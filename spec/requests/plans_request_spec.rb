require 'rails_helper'

RSpec.describe 'Plans', type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, :super_admin, company: company) }
  let(:general_user) { create(:user, :general, company: company) }
  let(:plan_category) { create(:category, :plan, user: super_admin_user) }
  let(:product_category) { create(:category, :product, user: super_admin_user) }
  let(:product) { create(:product, user: super_admin_user, category: product_category, company: company) }
  let!(:plan) { create(:plan, user: super_admin_user, category: plan_category) }

  describe 'GET /plans' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:resources_plans)
        expect(response).to have_http_status(:success)
      end

      it '@plansに計画を割り当てること' do
        get scoped_path(:resources_plans)
        expect(assigns(:plans)).to include(plan)
      end

      it 'indexテンプレートを表示すること' do
        get scoped_path(:resources_plans)
        expect(response).to render_template(:index)
      end

      it '@plan_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:resources_plans)
        expect(assigns(:plan_categories)).not_to be_nil
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get scoped_path(:resources_plans), params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'category_idパラメータでリクエストが成功すること' do
          get scoped_path(:resources_plans), params: { category_id: plan_category.id }
          expect(response).to have_http_status(:success)
        end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:resources_plans)
        expect([302, 404]).to include(response.status)
      end

  describe 'GET /plans/new' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:new_resources_plan)
        expect(response).to have_http_status(:success)
      end

      it '@planに新しい計画を割り当てること' do
        get scoped_path(:new_resources_plan)
        expect(assigns(:plan)).to be_a_new(Resources::Plan)
      end

      it '@plan_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:new_resources_plan)
        expect(assigns(:plan_categories)).not_to be_nil
      end

      it '@product_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:new_resources_plan)
        expect(assigns(:product_categories)).not_to be_nil
      end

      it 'newテンプレートを表示すること' do
        get scoped_path(:new_resources_plan)
        expect(response).to render_template(:new)
      end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:new_resources_plan)
        expect([302, 404]).to include(response.status)
      end

  describe 'POST /plans' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_plan: {
              name: '新しい計画',
              reading: 'あたらしいけいかく',
              category_id: plan_category.id,
              status: 'draft',
              description: 'テスト概要'
            }
          }
        end

        it '計画が作成されること' do
          expect {
            post scoped_path(:resources_plans), params: valid_params
          }.to change(Resources::Plan, :count).by(1)
        end

        it '作成された計画の詳細ページにリダイレクトされること' do
          post scoped_path(:resources_plans), params: valid_params
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          post scoped_path(:resources_plans), params: valid_params
          expect(response).to have_http_status(:redirect)
        end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_plan: {
              name: '',
              reading: '',
              category_id: plan_category.id
            }
          }
        end

        it '計画が作成されないこと' do
          expect {
            post scoped_path(:resources_plans), params: invalid_params
          }.not_to change(Resources::Plan, :count)
        end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post scoped_path(:resources_plans), params: { resources_plan: { name: 'テスト' } }
        expect([302, 404]).to include(response.status)
      end

  describe 'GET /plans/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:resources_plan, plan)
        expect(response).to have_http_status(:success)
      end

      it '@planに計画を割り当てること' do
        get scoped_path(:resources_plan, plan)
        expect(assigns(:plan)).to eq(plan)
      end

      it '@plan_productsに商品を割り当てること' do
        get scoped_path(:resources_plan, plan)
        expect(assigns(:plan_products)).not_to be_nil
      end

      it 'showテンプレートを表示すること' do
        get scoped_path(:resources_plan, plan)
        expect(response).to render_template(:show)
      end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:resources_plan, plan)
        expect([302, 404]).to include(response.status)
      end

  describe 'GET /plans/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:edit_resources_plan, plan)
        expect(response).to have_http_status(:success)
      end

      it '@planに計画を割り当てること' do
        get scoped_path(:edit_resources_plan, plan)
        expect(assigns(:plan)).to eq(plan)
      end

      it '@plan_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:edit_resources_plan, plan)
        expect(assigns(:plan_categories)).not_to be_nil
      end

      it '@product_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:edit_resources_plan, plan)
        expect(assigns(:product_categories)).not_to be_nil
      end

      it 'editテンプレートを表示すること' do
        get scoped_path(:edit_resources_plan, plan)
        expect(response).to render_template(:edit)
      end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:edit_resources_plan, plan)
        expect([302, 404]).to include(response.status)
      end

  describe 'PATCH /plans/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_plan: {
              name: '更新された計画名',
              description: '更新された概要'
            }
          }
        end

        it '計画が更新されること' do
          patch scoped_path(:resources_plan, plan), params: valid_params
          plan.reload
          expect(plan.name).to eq('更新された計画名')
        end

        it '更新された計画の詳細ページにリダイレクトされること' do
          patch scoped_path(:resources_plan, plan), params: valid_params
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          patch scoped_path(:resources_plan, plan), params: valid_params
          expect(response).to have_http_status(:redirect)
        end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_plan: {
              name: ''
            }
          }
        end

        it '計画が更新されないこと' do
          original_name = plan.name
          patch scoped_path(:resources_plan, plan), params: invalid_params
          plan.reload
          expect(plan.name).to eq(original_name)
        end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        expect(response).to have_http_status(:redirect)
        patch scoped_path(:resources_plan, plan), params: { resources_plan: { name: '更新' } }
        expect([302, 404]).to include(response.status)
      end

  describe 'DELETE /plans/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '計画が削除されること' do
        plan_to_delete = create(:plan, user: super_admin_user, category: plan_category)
        expect {
          delete scoped_path(:resources_plan, plan_to_delete)
        }.to change(Resources::Plan, :count).by(-1)
      end

      it '計画一覧にリダイレクトされること' do
        delete scoped_path(:resources_plan, plan)
        expect(response).to have_http_status(:redirect)
      end

      it '成功メッセージが表示されること' do
        delete scoped_path(:resources_plan, plan)
        expect(response).to have_http_status(:redirect)
      end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        expect(response).to have_http_status(:redirect)
        delete scoped_path(:resources_plan, plan)
        expect([302, 404]).to include(response.status)
      end

  describe 'PATCH /plans/:id/update_status' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なステータスの場合' do
        it 'ステータスが更新されること' do
          patch scoped_path(:update_status_resources_plan, plan), params: { status: 'active' }
          plan.reload
          expect(plan.status).to eq('active')
        end

        it '計画一覧にリダイレクトされること' do
          patch scoped_path(:update_status_resources_plan, plan), params: { status: 'active' }
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          patch scoped_path(:update_status_resources_plan, plan), params: { status: 'active' }
          expect(response).to have_http_status(:redirect)
        end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch scoped_path(:update_status_resources_plan, plan), params: { status: 'active' }
        expect([302, 404]).to include(response.status)
      end

  describe 'POST /plans/:id/copy' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      xit '計画がコピーされること' do
        post copy_plan_path(plan)
        expect(response).to have_http_status(:redirect)
      end

      it '計画一覧にリダイレクトされること' do
        post scoped_path(:copy_resources_plan, plan)
        expect(response).to have_http_status(:redirect)
      end

      it '成功メッセージが表示されること' do
        post scoped_path(:copy_resources_plan, plan)
        expect(response).to have_http_status(:redirect)
      end

      xit 'コピーされた計画の名前に「コピー」が含まれること' do
        post copy_plan_path(plan)
        expect(response).to have_http_status(:redirect)
      end

      it 'コピーされた計画のステータスがdraftになること' do
        post scoped_path(:copy_resources_plan, plan)
        copied_plan = Resources::Plan.last
        expect(copied_plan.status).to eq('draft')
      end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post scoped_path(:copy_resources_plan, plan)
        expect([302, 404]).to include(response.status)
      end

  describe 'GET /plans/:id/print' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:print_resources_plan, plan)
        expect(response).to have_http_status(:success)
      end

      it '@materials_summaryに材料集計を割り当てること' do
        get scoped_path(:print_resources_plan, plan)
        expect(assigns(:materials_summary)).not_to be_nil
      end

      it 'printテンプレートを表示すること' do
        get scoped_path(:print_resources_plan, plan)
        expect(response).to render_template(:print)
      end

      context '日付パラメータがある場合' do
        it '指定した日付が@scheduled_dateに割り当てられること' do
          date = Date.today
          get scoped_path(:print_resources_plan, plan), params: { date: date.to_s }
          expect(assigns(:scheduled_date)).to eq(date)
        end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        expect(response).to have_http_status(:redirect)
        get scoped_path(:print_resources_plan, plan)
        expect([302, 404]).to include(response.status)
      end

end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end
end