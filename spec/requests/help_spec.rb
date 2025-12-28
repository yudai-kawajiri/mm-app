require 'rails_helper'

RSpec.describe "Help", type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /help" do
    it "returns http success" do
      get scoped_path(:help)
      expect(response).to have_http_status(:success)
    end
  end
end
