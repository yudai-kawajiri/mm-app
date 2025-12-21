require 'rails_helper'

RSpec.describe "NumericalManagements", type: :request do
  let(:super_admin_user) { create(:user, :super_admin) }
  let(:general_user) { create(:user, :general) }
  let(:year) { Date.current.year }
  let(:month) { Date.current.month }
  let(:target_date) { Date.new(year, month, 15) }

  describe 'GET /numerical_managements' do
    context 'ログインしている場合' do
      before { sign_in super_admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(response).to have_http_status(:success)
      end

      it '@monthly_budgetに月次予算を割り当てること' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:monthly_budget)).not_to be_nil
      end

      it '@daily_targetsに日別目標を割り当てること' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:daily_targets)).not_to be_nil
      end

      it '@forecast_dataに予測データを割り当てること' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:forecast_data)).not_to be_nil
      end

      it '@daily_dataに日別データを割り当てること' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:daily_data)).not_to be_nil
      end

      it '@plans_by_categoryに計画を割り当てること' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:plans_by_category)).not_to be_nil
      end

      it 'indexテンプレートを表示すること' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(response).to render_template(:index)
      end

      context 'パラメータなしの場合' do
        it '現在の年月をデフォルトで使用すること' do
          get management_numerical_managements_path
          expect(response).to have_http_status(:success)
        end
      end

      context '異なる年月を指定した場合' do
        it '指定した年月のデータを取得すること' do
          get management_numerical_managements_path, params: { year: 2023, month: 6 }
          expect(response).to have_http_status(:success)
          expect(assigns(:selected_date)).to eq(Date.new(2023, 6, 1))
        end
      end

      context 'month パラメータにハイフン形式を指定した場合' do
        it '正しく年月を解析すること' do
          get management_numerical_managements_path, params: { month: "2023-06" }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'スタッフでログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(response).to have_http_status(:success)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get management_numerical_managements_path, params: { year: year, month: month }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
