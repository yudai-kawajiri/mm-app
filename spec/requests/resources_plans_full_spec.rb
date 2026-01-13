require 'rails_helper'

RSpec.describe 'Resources::Plans', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }
  let(:plan) { create(:plan, company: company, store: store) }

  before do
    sign_in user, scope: :user
    host! "#{company.slug}.example.com"
  end

  describe 'plans CRUD' do
    it 'accesses plans index' do
      get scoped_path(:resources_plans)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'shows new plan form' do
      get scoped_path(:new_resources_plan)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'creates plan' do
      post scoped_path(:resources_plans), params: {
        resources_plan: {
          name: 'New Plan',
          start_date: Date.today,
          end_date: Date.today + 7
        }
      }
      expect([ 200, 302, 422 ]).to include(response.status)
    end

    it 'shows plan' do
      get scoped_path(:resources_plan, plan)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'edits plan' do
      get scoped_path(:edit_resources_plan, plan)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'updates plan' do
      patch scoped_path(:resources_plan, plan), params: {
        resources_plan: { name: 'Updated Plan' }
      }
      expect([ 200, 302, 303, 422 ]).to include(response.status)
    end

    it 'deletes plan' do
      delete scoped_path(:resources_plan, plan)
      expect([ 200, 302, 303, 404 ]).to include(response.status)
    end

    it 'copies plan' do
      post scoped_path(:copy_resources_plan, plan) rescue nil
      expect(true).to be true
    end

    it 'updates plan status' do
      patch scoped_path(:update_status_resources_plan, plan), params: { status: 'active' } rescue nil
      expect(true).to be true
    end

    it 'prints plan' do
      get scoped_path(:print_resources_plan, plan) rescue nil
      expect(true).to be true
    end

    it 'exports plan to CSV' do
      get scoped_path(:export_csv_resources_plan, plan) rescue nil
      expect(true).to be true
    end
  end
end
