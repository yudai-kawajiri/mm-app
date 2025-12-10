require 'rails_helper'

RSpec.describe "Plans", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:staff_user) { create(:user, :staff) }
  let(:plan_category) { create(:category, :plan, user: admin_user) }
  let(:product_category) { create(:category, :product, user: admin_user) }
  let(:product) { create(:product, user: admin_user, category: product_category) }
  let!(:plan) { create(:plan, user: admin_user, category: plan_category) }

  describe 'GET /plans' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get resources_plans_path
        expect(response).to have_http_status(:success)
      end

      it '@plansに計画を割り当てること' do
        get resources_plans_path
        expect(assigns(:plans)).to include(plan)
      end

      it 'indexテンプレートを表示すること' do
        get resources_plans_path
        expect(response).to render_template(:index)
      end

      it '@plan_categoriesにカテゴリ―を割り当てること' do
        get resources_plans_path
        expect(assigns(:plan_categories)).not_to be_nil
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get resources_plans_path, params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'category_idパラメータでリクエストが成功すること' do
          get resources_plans_path, params: { category_id: plan_category.id }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get resources_plans_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /plans/new' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get new_resources_plan_path
        expect(response).to have_http_status(:success)
      end

      it '@planに新しい計画を割り当てること' do
        get new_resources_plan_path
        expect(assigns(:plan)).to be_a_new(Resources::Plan)
      end

      it '@plan_categoriesにカテゴリ―を割り当てること' do
        get new_resources_plan_path
        expect(assigns(:plan_categories)).not_to be_nil
      end

      it '@product_categoriesにカテゴリ―を割り当てること' do
        get new_resources_plan_path
        expect(assigns(:product_categories)).not_to be_nil
      end

      it 'newテンプレートを表示すること' do
        get new_resources_plan_path
        expect(response).to render_template(:new)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get new_resources_plan_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /plans' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

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
            post resources_plans_path, params: valid_params
          }.to change(Resources::Plan, :count).by(1)
        end

        it '作成された計画の詳細ページにリダイレクトされること' do
          post resources_plans_path, params: valid_params
          expect(response).to redirect_to(resources_plan_path(Resources::Plan.last))
        end

        it '成功メッセージが表示されること' do
          post resources_plans_path, params: valid_params
          expect(flash[:notice]).to be_present
        end
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
            post resources_plans_path, params: invalid_params
          }.not_to change(Resources::Plan, :count)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post resources_plans_path, params: { resources_plan: { name: 'テスト' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /plans/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get resources_plan_path(plan)
        expect(response).to have_http_status(:success)
      end

      it '@planに計画を割り当てること' do
        get resources_plan_path(plan)
        expect(assigns(:plan)).to eq(plan)
      end

      it '@plan_productsに商品を割り当てること' do
        get resources_plan_path(plan)
        expect(assigns(:plan_products)).not_to be_nil
      end

      it 'showテンプレートを表示すること' do
        get resources_plan_path(plan)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get resources_plan_path(plan)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /plans/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get edit_resources_plan_path(plan)
        expect(response).to have_http_status(:success)
      end

      it '@planに計画を割り当てること' do
        get edit_resources_plan_path(plan)
        expect(assigns(:plan)).to eq(plan)
      end

      it '@plan_categoriesにカテゴリ―を割り当てること' do
        get edit_resources_plan_path(plan)
        expect(assigns(:plan_categories)).not_to be_nil
      end

      it '@product_categoriesにカテゴリ―を割り当てること' do
        get edit_resources_plan_path(plan)
        expect(assigns(:product_categories)).not_to be_nil
      end

      it 'editテンプレートを表示すること' do
        get edit_resources_plan_path(plan)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get edit_resources_plan_path(plan)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /plans/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

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
          patch resources_plan_path(plan), params: valid_params
          plan.reload
          expect(plan.name).to eq('更新された計画名')
        end

        it '更新された計画の詳細ページにリダイレクトされること' do
          patch resources_plan_path(plan), params: valid_params
          expect(response).to redirect_to(resources_plan_path(plan))
        end

        it '成功メッセージが表示されること' do
          patch resources_plan_path(plan), params: valid_params
          expect(flash[:notice]).to be_present
        end
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
          patch resources_plan_path(plan), params: invalid_params
          plan.reload
          expect(plan.name).to eq(original_name)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch resources_plan_path(plan), params: { resources_plan: { name: '更新' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /plans/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '計画が削除されること' do
        plan_to_delete = create(:plan, user: admin_user, category: plan_category)
        expect {
          delete resources_plan_path(plan_to_delete)
        }.to change(Resources::Plan, :count).by(-1)
      end

      it '計画一覧にリダイレクトされること' do
        delete resources_plan_path(plan)
        expect(response).to redirect_to(resources_plans_url)
      end

      it '成功メッセージが表示されること' do
        delete resources_plan_path(plan)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete resources_plan_path(plan)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /plans/:id/update_status' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なステータスの場合' do
        it 'ステータスが更新されること' do
          patch update_status_resources_plan_path(plan), params: { status: 'active' }
          plan.reload
          expect(plan.status).to eq('active')
        end

        it '計画一覧にリダイレクトされること' do
          patch update_status_resources_plan_path(plan), params: { status: 'active' }
          expect(response).to redirect_to(resources_plans_path)
        end

        it '成功メッセージが表示されること' do
          patch update_status_resources_plan_path(plan), params: { status: 'active' }
          expect(flash[:notice]).to be_present
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch update_status_resources_plan_path(plan), params: { status: 'active' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /plans/:id/copy' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '計画がコピーされること' do
        expect {
          post copy_resources_plan_path(plan)
        }.to change(Resources::Plan, :count).by(1)
      end

      it '計画一覧にリダイレクトされること' do
        post copy_resources_plan_path(plan)
        expect(response).to redirect_to(resources_plans_path)
      end

      it '成功メッセージが表示されること' do
        post copy_resources_plan_path(plan)
        expect(flash[:notice]).to be_present
      end

      it 'コピーされた計画の名前に「コピー」が含まれること' do
        post copy_resources_plan_path(plan)
        copied_plan = Resources::Plan.last
        expect(copied_plan.name).to include('コピー')
      end

      it 'コピーされた計画のステータスがdraftになること' do
        post copy_resources_plan_path(plan)
        copied_plan = Resources::Plan.last
        expect(copied_plan.status).to eq('draft')
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post copy_resources_plan_path(plan)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /plans/:id/print' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get print_resources_plan_path(plan)
        expect(response).to have_http_status(:success)
      end

      it '@materials_summaryに材料集計を割り当てること' do
        get print_resources_plan_path(plan)
        expect(assigns(:materials_summary)).not_to be_nil
      end

      it 'printテンプレートを表示すること' do
        get print_resources_plan_path(plan)
        expect(response).to render_template(:print)
      end

      context '日付パラメータがある場合' do
        it '指定した日付が@scheduled_dateに割り当てられること' do
          date = Date.today
          get print_resources_plan_path(plan), params: { date: date.to_s }
          expect(assigns(:scheduled_date)).to eq(date)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get print_resources_plan_path(plan)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
