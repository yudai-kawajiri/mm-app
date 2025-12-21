require 'rails_helper'

RSpec.describe "ApplicationRequests", type: :request do
  before do
    host! 'example.com'
  end

  describe "GET /new" do
    it "returns http success" do
      get new_application_request_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      post application_requests_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /accept" do
    it "returns http success" do
      get accept_application_requests_path
      expect(response).to have_http_status(:success)
    end
  end
end
