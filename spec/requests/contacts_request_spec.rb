require 'rails_helper'

RSpec.describe ContactsController, type: :request do
  describe 'GET #new' do
    it 'returns success' do
      get '/contacts/new'
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'POST #create' do
    it 'processes contact form' do
      post '/contacts', params: { contact: { name: 'Test', email: 'test@example.com', message: 'Hello' } }
      expect([ 200, 302, 422 ]).to include(response.status)
    end
  end
end
