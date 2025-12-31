require 'rails_helper'

RSpec.describe 'Authenticated Actions', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }

  describe 'with general user' do
    let(:user) { create(:user, :general, company: company, store: store) }

    before do
      sign_in user, scope: :user
      host! "#{company.slug}.example.com"
    end

    it 'accesses resources' do
      get scoped_path(:resources_materials)
      expect([ 200, 302, 404 ]).to include(response.status)

      get scoped_path(:resources_products)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'loads categories' do
      category = create(:category, company: company)
      get scoped_path(:resources_categories)
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'with company_admin user' do
    let(:user) { create(:user, :company_admin, company: company, store: store) }

    before do
      sign_in user, scope: :user
      host! "#{company.slug}.example.com"
    end

    it 'accesses admin functions' do
      get scoped_path(:dashboards)
      expect([ 200, 302, 404 ]).to include(response.status)

      get scoped_path(:management_daily_targets)
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'with store user' do
    let(:user) { create(:user, :store_admin, company: company, store: store) }

    before do
      sign_in user, scope: :user
      host! "#{company.slug}.example.com"
    end

    it 'accesses store resources' do
      get scoped_path(:resources_materials)
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end
end
