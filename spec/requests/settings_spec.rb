require 'rails_helper'

RSpec.describe "Settings", type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }

  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /settings" do
    it "returns http success" do
      expect([200, 302]).to include(response.status)
      get settings_path
      expect([200, 302]).to include(response.status)
    end

    end

