require 'rails_helper'

RSpec.describe "DailyTargets", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:staff_user) { create(:user, :staff) }
  let(:year) { Date.current.year }
  let(:month) { Date.current.month }
  let(:budget_month) { Date.new(year, month, 1) }
  let(:target_date) { Date.new(year, month, 15) }
  let!(:monthly_budget) { create(:monthly_budget, user: admin_user, budget_month: budget_month) }

  describe 'POST /daily_targets' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            daily_target: {
              target_date: target_date.to_s,
              target_amount: 10000
            }
          }
        end

        it '日別目標が作成されること' do
          expect {
            post daily_targets_path, params: valid_params
          }.to change(DailyTarget, :count).by(1)
        end

        it '数値管理ページにリダイレクトされること' do
          post daily_targets_path, params: valid_params
          expect(response).to redirect_to(numerical_managements_path(month: target_date.strftime("%Y-%m")))
        end

        it '成功メッセージが表示されること' do
          post daily_targets_path, params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '既存の日別目標がある場合' do
        let!(:existing_target) { create(:daily_target, user: admin_user, monthly_budget: monthly_budget, target_date: target_date, target_amount: 5000) }

        let(:update_params) do
          {
            daily_target: {
              target_date: target_date.to_s,
              target_amount: 15000
            }
          }
        end

        it '新しい日別目標が作成されず、既存のものが更新されること' do
          expect {
            post daily_targets_path, params: update_params
          }.not_to change(DailyTarget, :count)
        end

        it '既存の目標金額が更新されること' do
          post daily_targets_path, params: update_params
          existing_target.reload
          expect(existing_target.target_amount).to eq(15000)
        end
      end

      context '月次予算が存在しない場合' do
        let(:no_budget_params) do
          {
            daily_target: {
              target_date: Date.new(year + 1, 1, 15).to_s,
              target_amount: 10000
            }
          }
        end

        it '日別目標が作成されないこと' do
          expect {
            post daily_targets_path, params: no_budget_params
          }.not_to change(DailyTarget, :count)
        end

        it 'エラーメッセージが表示されること' do
          post daily_targets_path, params: no_budget_params
          expect(flash[:alert]).to be_present
        end
      end

      context '無効な日付の場合' do
        let(:invalid_date_params) do
          {
            daily_target: {
              target_date: 'invalid-date',
              target_amount: 10000
            }
          }
        end

        it '日別目標が作成されないこと' do
          expect {
            post daily_targets_path, params: invalid_date_params
          }.not_to change(DailyTarget, :count)
        end

        it 'エラーメッセージが表示されること' do
          post daily_targets_path, params: invalid_date_params
          expect(flash[:alert]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            daily_target: {
              target_date: target_date.to_s,
              target_amount: nil
            }
          }
        end

        it '日別目標が作成されないこと' do
          expect {
            post daily_targets_path, params: invalid_params
          }.not_to change(DailyTarget, :count)
        end

        it 'エラーメッセージが表示されること' do
          post daily_targets_path, params: invalid_params
          expect(flash[:alert]).to be_present
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post daily_targets_path, params: { daily_target: { target_date: target_date.to_s, target_amount: 10000 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /daily_targets/:id' do
    let!(:daily_target) { create(:daily_target, user: admin_user, monthly_budget: monthly_budget, target_date: target_date, target_amount: 8000) }

    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            daily_target: {
              target_date: target_date.to_s,
              target_amount: 12000
            }
          }
        end

        it '日別目標が更新されること' do
          patch daily_target_path(daily_target), params: valid_params
          daily_target.reload
          expect(daily_target.target_amount).to eq(12000)
        end

        it '数値管理ページにリダイレクトされること' do
          patch daily_target_path(daily_target), params: valid_params
          expect(response).to redirect_to(numerical_managements_path(month: target_date.strftime("%Y-%m")))
        end

        it '成功メッセージが表示されること' do
          patch daily_target_path(daily_target), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            daily_target: {
              target_date: target_date.to_s,
              target_amount: nil
            }
          }
        end

        it '日別目標が更新されないこと' do
          original_amount = daily_target.target_amount
          patch daily_target_path(daily_target), params: invalid_params
          daily_target.reload
          expect(daily_target.target_amount).to eq(original_amount)
        end

        it 'エラーメッセージが表示されること' do
          patch daily_target_path(daily_target), params: invalid_params
          expect(flash[:alert]).to be_present
        end
      end

      context '他のユーザーの日別目標を更新しようとした場合' do
        let(:other_user) { create(:user, :staff) }
        let(:other_monthly_budget) { create(:monthly_budget, user: other_user, budget_month: budget_month) }
        let(:other_daily_target) { create(:daily_target, user: other_user, monthly_budget: other_monthly_budget, target_date: target_date) }

        let(:unauthorized_params) do
          {
            daily_target: {
              target_date: target_date.to_s,
              target_amount: 20000
            }
          }
        end

        it '日別目標が更新されないこと' do
          original_amount = other_daily_target.target_amount
          patch daily_target_path(other_daily_target), params: unauthorized_params
          other_daily_target.reload
          expect(other_daily_target.target_amount).to eq(original_amount)
        end

        it 'エラーメッセージが表示されること' do
          patch daily_target_path(other_daily_target), params: unauthorized_params
          expect(flash[:alert]).to be_present
        end

        it '数値管理ページにリダイレクトされること' do
          patch daily_target_path(other_daily_target), params: unauthorized_params
          expect(response).to redirect_to(numerical_managements_path)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch daily_target_path(daily_target), params: { daily_target: { target_amount: 15000 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
