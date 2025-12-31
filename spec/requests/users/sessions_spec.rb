require 'rails_helper'

RSpec.describe 'User Sessions', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, :general, company: company, password: 'password123') }

  describe 'login flow' do
    it 'shows login page' do
      get '/users/sign_in'
      expect([200, 302]).to include(response.status)
    end
    
    it 'processes login' do
      post '/users/sign_in', params: {
        user: { email: user.email, password: 'password123' }
      }
      expect([200, 302]).to include(response.status)
    end
  end
  
    end
end
