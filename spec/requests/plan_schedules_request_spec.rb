require 'rails_helper'

RSpec.describe "PlanSchedules", type: :request do
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, :super_admin, company: company) }
  let(:general_user) { create(:user, :general, company: company) }
  let(:year) { Date.current.year }
  let(:month) { Date.current.month }
  let(:scheduled_date) { Date.new(year, month, 15) }
  let(:plan_category) { create(:category, :plan, user: super_admin_user) }
  let(:plan) { create(:plan, :active, user: super_admin_user, category: plan_category) }

  describe 'POST /plan_schedules' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            plan_schedule: {
              scheduled_date: scheduled_date.to_s,
              plan_id: plan.id

            }
          }
        end

        it '計画スケジュールが作成されること' do
          expect {
            post scoped_path(:management_plan_schedules), params: valid_params
          }.to change(Planning::PlanSchedule, :count).by(1)
        end

        it '数値管理ページにリダイレクトされること' do
          post scoped_path(:management_plan_schedules), params: valid_params
          expect(response).to redirect_to(scoped_path(:management_numerical_managements, year: scheduled_date.year, month: scheduled_date.month))
        end

        it '成功メッセージが表示されること' do
          post scoped_path(:management_plan_schedules), params: valid_params
          expect(flash[:notice]).to be_present
        end

        it 'ステータスがscheduledになること' do
          post scoped_path(:management_plan_schedules), params: valid_params
          created_schedule = Planning::PlanSchedule.last
          expect(created_schedule.status).to eq('scheduled')
        end
      end

      context '同じ日に既に計画がある場合' do
        let!(:existing_schedule) { create(:plan_schedule, user: super_admin_user, plan: plan, scheduled_date: scheduled_date) }

        let(:update_params) do
          {
            plan_schedule: {
              scheduled_date: scheduled_date.to_s,
              plan_id: plan.id

            }
          }
        end

        it '新しい計画スケジュールが作成されず、既存のものが更新されること' do
          expect {
            post scoped_path(:management_plan_schedules), params: update_params
          }.not_to change(Planning::PlanSchedule, :count)
        end

        it '既存のスケジュールが更新されること' do
          post scoped_path(:management_plan_schedules), params: update_params
          existing_schedule.reload
        end
      end

      context 'plan_idが指定されていない場合' do
        let(:missing_plan_params) do
          {
            plan_schedule: {
              scheduled_date: scheduled_date.to_s

            }
          }
        end

        it '計画スケジュールが作成されないこと' do
          expect {
            post scoped_path(:management_plan_schedules), params: missing_plan_params
          }.not_to change(Planning::PlanSchedule, :count)
        end

        it 'エラーメッセージが表示されること' do
          post scoped_path(:management_plan_schedules), params: missing_plan_params
          expect(flash[:alert]).to be_present
        end
      end

      context '無効な日付の場合' do
        let(:invalid_date_params) do
          {
            plan_schedule: {
              scheduled_date: 'invalid-date',
              plan_id: plan.id

            }
          }
        end

        it '計画スケジュールが作成されないこと' do
          expect {
            post scoped_path(:management_plan_schedules), params: invalid_date_params
          }.not_to change(Planning::PlanSchedule, :count)
        end

        it 'エラーメッセージが表示されること' do
          post scoped_path(:management_plan_schedules), params: invalid_date_params
          expect(flash[:alert]).to be_present
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post scoped_path(:management_plan_schedules), params: { plan_schedule: { scheduled_date: scheduled_date.to_s, plan_id: 1 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /plan_schedules/:id' do
    let!(:plan_schedule) { create(:plan_schedule, user: super_admin_user, plan: plan, scheduled_date: scheduled_date) }

    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            plan_schedule: {
              scheduled_date: scheduled_date.to_s,
              plan_id: plan.id

            }
          }
        end

        it '計画スケジュールが更新されること' do
          patch scoped_path(:management_plan_schedule, plan_schedule), params: valid_params
          plan_schedule.reload
        end

        it '数値管理ページにリダイレクトされること' do
          patch scoped_path(:management_plan_schedule, plan_schedule), params: valid_params
          expect(response).to redirect_to(scoped_path(:management_numerical_managements, year: scheduled_date.year, month: scheduled_date.month))
        end

        it '成功メッセージが表示されること' do
          patch scoped_path(:management_plan_schedule, plan_schedule), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch scoped_path(:management_plan_schedule, plan_schedule), params: { plan_schedule: {} }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /plan_schedules/:id/actual_revenue' do
    let!(:plan_schedule) { create(:plan_schedule, user: super_admin_user, plan: plan, scheduled_date: scheduled_date) }

    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            plan_schedule: {
              actual_revenue: 55000
            }
          }
        end

        it '実績が更新されること' do
          patch scoped_path(:actual_revenue_management_plan_schedule, plan_schedule), params: valid_params
          plan_schedule.reload
          expect(plan_schedule.actual_revenue).to eq(55000)
        end

        it '数値管理ページにリダイレクトされること' do
          patch scoped_path(:actual_revenue_management_plan_schedule, plan_schedule), params: valid_params
          expect(response).to redirect_to(scoped_path(:management_numerical_managements, year: scheduled_date.year, month: scheduled_date.month))
        end

        it '成功メッセージが表示されること' do
          patch scoped_path(:actual_revenue_management_plan_schedule, plan_schedule), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            plan_schedule: {
              actual_revenue: -1000
            }
          }
        end

        it '実績が更新されないこと' do
          original_revenue = plan_schedule.actual_revenue
          patch scoped_path(:actual_revenue_management_plan_schedule, plan_schedule), params: invalid_params
          plan_schedule.reload
          expect(plan_schedule.actual_revenue).to eq(original_revenue)
        end

        it 'エラーメッセージが表示されること' do
          patch scoped_path(:actual_revenue_management_plan_schedule, plan_schedule), params: invalid_params
          expect(flash[:alert]).to be_present
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch scoped_path(:actual_revenue_management_plan_schedule, plan_schedule), params: { plan_schedule: { actual_revenue: 60000 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
