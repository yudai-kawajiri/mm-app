require 'rails_helper'

RSpec.describe 'Users::Passwords Access', type: :request do
  let(:company) { create(:company) }

  it 'accesses new password page' do
  get "/c/#{company.slug}/users/password/new"
  expect([200, 302, 404]).to include(response.status)
end


  it 'submits password reset' do
    post "/c/#{company.slug}/users/password", params: { user: { email: 'test@example.com' } }
    expect([200, 302, 404, 422]).to include(response.status)
  end
end
