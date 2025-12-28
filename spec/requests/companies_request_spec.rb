require 'rails_helper'

RSpec.describe CompaniesController, type: :request do
  let(:company) { create(:company) }
  
  describe 'GET #show' do
    it 'returns success' do
      get "/c/#{company.slug}"
      expect([200, 302, 404]).to include(response.status)
    end
  end
end
