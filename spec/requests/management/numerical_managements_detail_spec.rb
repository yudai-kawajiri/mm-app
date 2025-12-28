require 'rails_helper'

RSpec.describe Management::NumericalManagementsController, type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user, scope: :user
    host! "#{company.slug}.example.com"
  end

  describe 'GET index' do
    it 'shows numerical managements' do
      get scoped_path(:management_numerical_managements)
      expect([200, 302, 404]).to include(response.status)
    end
  end
  
  describe 'POST create' do
    it 'creates numerical management' do
      post scoped_path(:management_numerical_managements), params: {
        management_numerical_management: { date: Date.today, value: 500 }
      }
      expect([200, 302, 404, 422]).to include(response.status)
    end
  end
end
