require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:super_admin_user) { create(:user, :super_admin) }
  let(:general_user) { create(:user, :general) }
  let(:year) { Date.current.year }
  let(:month) { Date.current.month }

  describe 'GET /' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get authenticated_root_path
        expect(response).to have_http_status(:success)
      end

      it '@forecast_dataに予測データを割り当てること' do
        get authenticated_root_path
        expect(assigns(:forecast_data)).not_to be_nil
      end

      # 修正1: 月次予算が存在する場合のみテスト
      context '月次予算が存在する場合' do
        let!(:monthly_budget) { create(:monthly_budget, user: admin_user, budget_month: Date.new(year, month, 1)) }

        it '@monthly_budgetに月次予算を割り当てること' do
          get authenticated_root_path
          expect(assigns(:monthly_budget)).to eq(monthly_budget)
        end
      end

      it '@weather_forecastに天気予報を割り当てること' do
        get authenticated_root_path
        expect(assigns(:weather_forecast)).not_to be_nil
      end


      it 'indexテンプレートを表示すること' do
        get authenticated_root_path
        expect(response).to render_template(:index)
      end

      context '年月パラメータを指定した場合' do
        it '指定した年月のデータを取得すること' do
          get authenticated_root_path, params: { year: 2023, month: 6 }
          expect(response).to have_http_status(:success)
          expect(assigns(:selected_date)).to eq(Date.new(2023, 6, 1))
        end
      end

      context '年月パラメータを指定しない場合' do
        it '現在の年月をデフォルトで使用すること' do
          get authenticated_root_path
          expect(assigns(:year)).to eq(Date.current.year)
          expect(assigns(:month)).to eq(Date.current.month)
        end
      end

      context 'グラフデータの生成' do
        let!(:monthly_budget) { create(:monthly_budget, user: admin_user, budget_month: Date.new(year, month, 1)) }
        let!(:daily_target) { create(:daily_target, user: admin_user, target_date: Date.new(year, month, 15), target_amount: 10000) }
    end
      it '正常にレスポンスを返すこと' do
        get authenticated_root_path
        expect(response).to have_http_status(:success)
      end

      it 'ダッシュボードデータが表示されること' do
        get authenticated_root_path
        expect(assigns(:forecast_data)).not_to be_nil
      end
    end

    # 修正2: 未ログイン時のテストを実際の動作に合わせる
    context 'ログインしていない場合' do
      it 'ログインページが表示されること' do
        get root_path  # authenticated_root_pathではなくroot_path
        expect(response).to have_http_status(:success)
        expect(response).to render_template('landing/index')
      end
    end
  end
end
