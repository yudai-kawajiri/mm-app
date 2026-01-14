# frozen_string_literal: true

module DeviseHelpers
  def sign_in(user)
    # Warden を使って直接ログイン
    login_as(user, scope: :user)
  end
end

RSpec.configure do |config|
  config.include DeviseHelpers, type: :request
  config.include Warden::Test::Helpers, type: :request

  config.after(:each, type: :request) do
    Warden.test_reset!
  end
end
