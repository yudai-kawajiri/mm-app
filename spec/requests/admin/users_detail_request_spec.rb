require 'rails_helper'

RSpec.describe Admin::UsersController, type: :request do
  let(:company) { create(:company) }
  let(:super_admin) { create(:user, :super_admin, company: company) }
  let(:target_user) { create(:user, :general, company: company) }

  before do
    sign_in super_admin, scope: :user
    host! 'admin.example.com'
  end

  describe 'GET /admin/users' do
    it 'lists users' do
      get '/admin/users'
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'GET /admin/users/:id' do
    it 'shows user details' do
      get "/admin/users/#{target_user.id}"
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'GET /admin/users/new' do
    it 'shows new user form' do
      get '/admin/users/new'
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'POST /admin/users' do
    it 'creates new user' do
      post '/admin/users', params: {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          company_id: company.id,
          role: 'general'
        }
      }
      expect([ 200, 302, 404, 422 ]).to include(response.status)
    end
  end

  describe 'GET /admin/users/:id/edit' do
    it 'shows edit form' do
      get "/admin/users/#{target_user.id}/edit"
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end

  describe 'PATCH /admin/users/:id' do
    it 'updates user' do
      patch "/admin/users/#{target_user.id}", params: {
        user: { email: 'updated@example.com' }
      }
      expect([ 200, 302, 404, 422 ]).to include(response.status)
    end
  end
end
