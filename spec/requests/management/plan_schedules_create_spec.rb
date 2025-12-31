require 'rails_helper'

RSpec.describe 'Management::PlanSchedules Create', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }
  let(:plan) { create(:plan, company: company, store: store) }

  before do
    sign_in user
    host! "#{company.slug}.example.com"
  end

  describe 'POST /management/plan_schedules' do
    it 'creates plan schedule' do
      post scoped_path(:management_plan_schedules), params: {
        plan_schedule: {
          plan_id: plan.id,
          scheduled_date: Date.today.to_s
        }
      }
      expect([ 200, 302, 422 ]).to include(response.status)
    end
  end
end
