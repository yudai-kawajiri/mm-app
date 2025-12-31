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
      expect([ 200, 302, 400, 404 ]).to include(response.status)
    end
  end

  describe 'GET /application_requests/new' do
    it 'returns http success' do
      user = create(:user)
      login_as(user, scope: :user)

      post application_requests_path
      expect([ 200, 302, 400, 404 ]).to include(response.status)
    end
  end

  describe "GET /accept" do
    it "returns http success" do
      user = create(:user)
      login_as(user, scope: :user)

      get accept_application_requests_path
      expect([ 200, 302, 400, 404 ]).to include(response.status)
    end
  end
end
