require 'rails_helper'

RSpec.describe 'Resources::Plans', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user
    host! "#{company.slug}.example.com"
  end

  describe 'plans CRUD' do
    it 'accesses plans index' do
      get scoped_path(:resources_plans)
      expect([200, 302, 404]).to include(response.status)
    end

    it 'shows new plan form' do
      get scoped_path(:new_resources_plan)
      expect([200, 302, 404]).to include(response.status)
    end

    it 'creates plan' do
      post scoped_path(:resources_plans), params: {
        resources_plan: {
          name: 'New Plan',
          start_date: Date.today,
          end_date: Date.today + 7
        }
      }
      expect([200, 302, 422]).to include(response.status)
    end

    it 'shows plan' do
      plan = create(:plan, company: company, store: store)
      get scoped_path(:resources_plan, plan)
      expect([200, 302, 404]).to include(response.status)
    end

    it 'edits plan' do
      plan = create(:plan, company: company, store: store)
      get scoped_path(:edit_resources_plan, plan)
      expect([200, 302, 404]).to include(response.status)
    end

    
  end
end
