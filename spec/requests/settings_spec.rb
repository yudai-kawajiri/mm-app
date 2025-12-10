require 'rails_helper'

RSpec.describe "Settings", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /settings" do
    it "returns http success" do
      get settings_path
      expect(response).to have_http_status(:success)
    end
  end
end
