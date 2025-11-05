require 'rails_helper'

RSpec.describe "NumericalManagements", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:staff_user) { create(:user, :staff) }
  let(:year) { Date.current.year }
  let(:month) { Date.current.month }
  let(:target_date) { Date.new(year, month, 15) }

  describe 'GET /numerical_managements' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(response).to have_http_status(:success)
      end

      it '@monthly_budgetに月次予算を割り当てること' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:monthly_budget)).not_to be_nil
      end

      it '@daily_targetsに日別目標を割り当てること' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:daily_targets)).not_to be_nil
      end

      it '@forecast_dataに予測データを割り当てること' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:forecast_data)).not_to be_nil
      end

      it '@daily_dataに日別データを割り当てること' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:daily_data)).not_to be_nil
      end

      it '@plans_by_categoryに計画を割り当てること' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(assigns(:plans_by_category)).not_to be_nil
      end

      it 'indexテンプレートを表示すること' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(response).to render_template(:index)
      end

      context 'パラメータなしの場合' do
        it '現在の年月をデフォルトで使用すること' do
          get numerical_managements_path
          expect(response).to have_http_status(:success)
        end
      end

      context '異なる年月を指定した場合' do
        it '指定した年月のデータを取得すること' do
          get numerical_managements_path, params: { year: 2023, month: 6 }
          expect(response).to have_http_status(:success)
          expect(assigns(:selected_date)).to eq(Date.new(2023, 6, 1))
        end
      end

      context 'month パラメータにハイフン形式を指定した場合' do
        it '正しく年月を解析すること' do
          get numerical_managements_path, params: { month: "2023-06" }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'スタッフでログインしている場合' do
      before { sign_in staff_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(response).to have_http_status(:success)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get numerical_managements_path, params: { year: year, month: month }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /numerical_managements/bulk_update' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            year: year,
            month: month,
            daily_data: {
              '0' => {
                date: target_date.to_s,
                target_amount: 5000
              },
              '1' => {
                date: Date.new(year, month, 16).to_s,
                target_amount: 6000
              }
            }
          }
        end

        it '数値管理ページにリダイレクトされること' do
          post bulk_update_numerical_managements_path, params: valid_params
          expect(response).to redirect_to(numerical_managements_path(year: year, month: month))
        end

        it 'フラッシュメッセージが表示されること' do
          post bulk_update_numerical_managements_path, params: valid_params
          expect(flash[:notice] || flash[:alert]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            year: year,
            month: month,
            daily_data: 'invalid'
          }
        end

        it 'エラーメッセージが表示されること' do
          post bulk_update_numerical_managements_path, params: invalid_params
          expect(flash[:alert]).to be_present
        end

        it '数値管理ページにリダイレクトされること' do
          post bulk_update_numerical_managements_path, params: invalid_params
          expect(response).to redirect_to(numerical_managements_path(year: year, month: month))
        end
      end

      context '既存のデータを更新する場合' do
        let!(:daily_target) { create(:daily_target, user: admin_user, target_date: target_date, target_amount: 3000) }

        let(:update_params) do
          {
            year: year,
            month: month,
            daily_data: {
              '0' => {
                date: target_date.to_s,
                target_id: daily_target.id,
                target_amount: 8000
              }
            }
          }
        end

        it '数値管理ページにリダイレクトされること' do
          post bulk_update_numerical_managements_path, params: update_params
          expect(response).to redirect_to(numerical_managements_path(year: year, month: month))
        end
      end
    end

    context 'スタッフでログインしている場合' do
      before { sign_in staff_user, scope: :user }

      let(:valid_params) do
        {
          year: year,
          month: month,
          daily_data: {
            '0' => {
              date: target_date.to_s,
              target_amount: 5000
            }
          }
        }
      end

      it '一括更新が成功すること' do
        post bulk_update_numerical_managements_path, params: valid_params
        expect(response).to redirect_to(numerical_managements_path(year: year, month: month))
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post bulk_update_numerical_managements_path, params: { year: year, month: month }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
