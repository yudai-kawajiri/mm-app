require 'rails_helper'

RSpec.describe "ApplicationRequests", type: :request do
  let(:company) { create(:company) }
  before do
    host! 'example.com'
  end

  describe "GET /new" do
    it "returns http success" do
      user = create(:user)
      login_as(user, scope: :user)

      get new_application_request_path
      expect(response).to have_http_status(:ok).or have_http_status(:redirect)
    end
  end

  describe 'GET /application_requests/new' do
    it 'returns http success' do
      expect([200, 302]).to include(response.status)
      user = create(:user)
      login_as(user, scope: :user)

      post application_requests_path
      expect(response).to have_http_status(:ok).or have_http_status(:redirect)
    end
  end

  describe "GET /accept" do
      expect([200, 302]).to include(response.status)
      user = create(:user)
      login_as(user, scope: :user)

      get accept_application_requests_path
      expect(response).to have_http_status(:ok).or have_http_status(:redirect)
    end
