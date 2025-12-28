require 'rails_helper'

RSpec.describe "MonthlyBudgets", type: :request do
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, :super_admin, company: company) }
  let(:general_user) { create(:user, :general, company: company) }
  let(:year) { Date.current.year }
  let(:month) { Date.current.month }
  let(:budget_month) { Date.new(year, month, 1) }

  describe 'POST /monthly_budgets' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            year: year,
            month: month,
            monthly_budget: {
              target_amount: 300000,
              description: 'テストノート'
            }
          }
        end

        it '月次予算が作成されること' do
          expect {
            post scoped_path(:management_monthly_budgets), params: valid_params
          }.to change(Management::MonthlyBudget, :count).by(1)
        end

        it '数値管理ページにリダイレクトされること' do
          post scoped_path(:management_monthly_budgets), params: valid_params
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          post scoped_path(:management_monthly_budgets), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            year: year,
            month: month,
            monthly_budget: {
              target_amount: nil
            }
          }
        end

        it '月次予算が作成されないこと' do
          expect {
            post scoped_path(:management_monthly_budgets), params: invalid_params
          }.not_to change(Management::MonthlyBudget, :count)
        end

        it 'エラーメッセージが表示されること' do
          post scoped_path(:management_monthly_budgets), params: invalid_params
          expect(flash[:alert]).to be_present
        end

        it '数値管理ページにリダイレクトされること' do
          post scoped_path(:management_monthly_budgets), params: invalid_params
          expect(response).to have_http_status(:redirect)
        end
      end

      context '既存の月次予算がある場合' do
        let!(:existing_budget) { create(:monthly_budget, budget_month: budget_month, target_amount: 200000) }

        let(:update_params) do
          {
            year: year,
            month: month,
            monthly_budget: {
              target_amount: 350000
            }
          }
        end

        it '新しい月次予算が作成されず、既存のものが更新されること' do
          expect {
            post scoped_path(:management_monthly_budgets), params: update_params
          }.not_to change(Management::MonthlyBudget, :count)
        end

          expect(response).to have_http_status(:redirect)
        post monthly_budgets_path, params: { monthly_budget: valid_attributes }
        expect(response).to have_http_status(:redirect)
      end
      end
    end

    context 'ログインしていない場合' do
        expect(response).to have_http_status(:redirect)
        post scoped_path(:management_monthly_budgets), params: { year: year, month: month }
        expect(response).to have_http_status(:redirect)
      end
    end

  describe 'PATCH /monthly_budgets/:id' do
    let!(:monthly_budget) { create(:monthly_budget, budget_month: budget_month, target_amount: 200000, user: general_user, company: general_user.company) }

    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            monthly_budget: {
              target_amount: 400000,
              description: '更新されたノート'
            }
          }
        end

        it '月次予算が更新されること' do
          patch scoped_path(:management_monthly_budget, monthly_budget), params: valid_params
          monthly_budget.reload
          expect(monthly_budget.target_amount).to eq(400000)
        end

        it '数値管理ページにリダイレクトされること' do
          patch scoped_path(:management_monthly_budget, monthly_budget), params: valid_params
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          patch scoped_path(:management_monthly_budget, monthly_budget), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            monthly_budget: {
              target_amount: nil
            }
          }
        end

        it '月次予算が更新されないこと' do
          original_amount = monthly_budget.target_amount
          patch scoped_path(:management_monthly_budget, monthly_budget), params: invalid_params
          monthly_budget.reload
          expect(monthly_budget.target_amount).to eq(original_amount)
        end

        it 'エラーメッセージが表示されること' do
          patch scoped_path(:management_monthly_budget, monthly_budget), params: invalid_params
          expect(flash[:alert]).to be_present
        end
      end
    end

    context 'ログインしていない場合' do
        expect(response).to have_http_status(:redirect)
        patch scoped_path(:management_monthly_budget, monthly_budget), params: { monthly_budget: { target_amount: 300000 } }
        expect(response).to have_http_status(:redirect)
      end
    end

  describe 'DELETE /monthly_budgets/:id' do
    let!(:monthly_budget) { create(:monthly_budget, budget_month: budget_month, user: general_user, company: general_user.company) }

    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '月次予算が削除されること' do
        expect {
          delete scoped_path(:management_monthly_budget, monthly_budget)
        }.to change(Management::MonthlyBudget, :count).by(-1)
      end

      it '数値管理ページにリダイレクトされること' do
        delete scoped_path(:management_monthly_budget, monthly_budget)
        expect(response).to have_http_status(:redirect)
      end

      it '成功メッセージが表示されること' do
        delete scoped_path(:management_monthly_budget, monthly_budget)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
        expect(response).to have_http_status(:redirect)
        delete scoped_path(:management_monthly_budget, monthly_budget)
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
