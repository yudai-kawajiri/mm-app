require 'rails_helper'

RSpec.describe "ApplicationRequests", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/application_requests/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/application_requests/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /accept" do
    it "returns http success" do
      get "/application_requests/accept"
      expect(response).to have_http_status(:success)
    end
  end

end
