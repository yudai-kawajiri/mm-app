require 'rails_helper'

RSpec.describe "MonthlyBudgets", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:staff_user) { create(:user, :staff) }
  let(:year) { Date.current.year }
  let(:month) { Date.current.month }
  let(:budget_month) { Date.new(year, month, 1) }

  describe 'POST /monthly_budgets' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

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
            post monthly_budgets_path, params: valid_params
          }.to change(MonthlyBudget, :count).by(1)
        end

        it '数値管理ページにリダイレクトされること' do
          post monthly_budgets_path, params: valid_params
          expect(response).to redirect_to(numerical_managements_path(month: budget_month.strftime("%Y-%m")))
        end

        it '成功メッセージが表示されること' do
          post monthly_budgets_path, params: valid_params
          expect(flash[:notice]).to be_present
        end

        it '日別目標が自動生成されること' do
          expect {
            post monthly_budgets_path, params: valid_params
          }.to change(DailyTarget, :count).by_at_least(1)
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
            post monthly_budgets_path, params: invalid_params
          }.not_to change(MonthlyBudget, :count)
        end

        it 'エラーメッセージが表示されること' do
          post monthly_budgets_path, params: invalid_params
          expect(flash[:alert]).to be_present
        end

        it '数値管理ページにリダイレクトされること' do
          post monthly_budgets_path, params: invalid_params
          expect(response).to redirect_to(numerical_managements_path(month: budget_month.strftime("%Y-%m")))
        end
      end

      context '既存の月次予算がある場合' do
        let!(:existing_budget) { create(:monthly_budget, user: admin_user, budget_month: budget_month, target_amount: 200000) }

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
            post monthly_budgets_path, params: update_params
          }.not_to change(MonthlyBudget, :count)
        end

        it '既存の予算金額が更新されること' do
          post monthly_budgets_path, params: update_params
          existing_budget.reload
          expect(existing_budget.target_amount).to eq(350000)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post monthly_budgets_path, params: { year: year, month: month }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /monthly_budgets/:id' do
    let!(:monthly_budget) { create(:monthly_budget, user: admin_user, budget_month: budget_month, target_amount: 200000) }

    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

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
          patch monthly_budget_path(monthly_budget), params: valid_params
          monthly_budget.reload
          expect(monthly_budget.target_amount).to eq(400000)
        end

        it '数値管理ページにリダイレクトされること' do
          patch monthly_budget_path(monthly_budget), params: valid_params
          expect(response).to redirect_to(numerical_managements_path(month: budget_month.strftime("%Y-%m")))
        end

        it '成功メッセージが表示されること' do
          patch monthly_budget_path(monthly_budget), params: valid_params
          expect(flash[:notice]).to be_present
        end

        it '日別目標が再生成されること' do
          # 既存の日別目標を作成
          create(:daily_target, user: admin_user, target_date: budget_month, target_amount: 5000)

          # 更新時に削除されて再生成される
          expect {
            patch monthly_budget_path(monthly_budget), params: valid_params
          }.to change { admin_user.daily_targets.where(target_date: budget_month..budget_month.end_of_month).count }
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
          patch monthly_budget_path(monthly_budget), params: invalid_params
          monthly_budget.reload
          expect(monthly_budget.target_amount).to eq(original_amount)
        end

        it 'エラーメッセージが表示されること' do
          patch monthly_budget_path(monthly_budget), params: invalid_params
          expect(flash[:alert]).to be_present
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch monthly_budget_path(monthly_budget), params: { monthly_budget: { target_amount: 300000 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /monthly_budgets/:id' do
    let!(:monthly_budget) { create(:monthly_budget, user: admin_user, budget_month: budget_month) }

    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '月次予算が削除されること' do
        expect {
          delete monthly_budget_path(monthly_budget)
        }.to change(MonthlyBudget, :count).by(-1)
      end

      it '数値管理ページにリダイレクトされること' do
        delete monthly_budget_path(monthly_budget)
        expect(response).to redirect_to(numerical_managements_path(month: budget_month.strftime("%Y-%m")))
      end

      it '成功メッセージが表示されること' do
        delete monthly_budget_path(monthly_budget)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete monthly_budget_path(monthly_budget)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
