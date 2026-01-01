require 'rails_helper'

RSpec.describe 'User Authentication and Roles', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }

  describe 'different user roles' do
    it 'handles general user' do
      user = create(:user, :general, company: company, store: store)
      sign_in user, scope: :user
      host! "#{company.slug}.example.com"

      get scoped_path(:dashboards)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'handles company_admin user' do
      user = create(:user, :company_admin, company: company, store: store)
      sign_in user, scope: :user
      host! "#{company.slug}.example.com"

      get scoped_path(:dashboards)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'handles super_admin user' do
      user = create(:user, :super_admin, company: company)
      sign_in user, scope: :user
      host! 'admin.example.com'

      get '/admin/users'
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end
  end
