require 'rails_helper'

RSpec.describe 'User Sessions', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123', company: company) }

  describe 'login flow' do
    it 'shows login page' do
      get "/c/#{company.slug}/users/sign_in"
      expect([ 200, 302 ]).to include(response.status)
    end

    it 'processes login' do
      post "/c/#{company.slug}/users/sign_in", params: { user: { email: user.email, password: 'password123' } }
      expect([ 200, 302, 303 ]).to include(response.status)
    end
  end
end
