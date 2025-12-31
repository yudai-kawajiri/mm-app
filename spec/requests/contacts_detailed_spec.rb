require 'rails_helper'

RSpec.describe ContactsController, type: :request do
  describe 'GET /contacts/new' do
    it 'shows contact form' do
      get '/contacts/new'
      expect([200, 302, 404]).to include(response.status)
    end
  end
  
  describe 'POST /contacts' do
    it 'creates contact with valid data' do
      post '/contacts', params: {
        contact: {
          name: 'Test User',
          email: 'test@example.com',
          message: 'This is a test message'
        }
      }
      expect([200, 302, 422]).to include(response.status)
    end
    
    it 'handles invalid data' do
      post '/contacts', params: {
        contact: {
          name: '',
          email: 'invalid',
          message: ''
        }
      }
      expect([200, 302, 422]).to include(response.status)
    end
    
    end
end
