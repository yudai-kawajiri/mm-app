require 'rails_helper'

RSpec.describe "Settings", type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /settings" do
    it "returns http success" do
      get scoped_path(:settings)
      expect(response).to have_http_status(:success)
    end
  end
end
