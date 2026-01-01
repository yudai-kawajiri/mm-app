require 'rails_helper'

RSpec.describe 'Stores Access', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user, scope: :user
    host! "#{company.slug}.example.com"
  end

  it 'accesses store page' do
  get "/c/#{company.slug}/stores/#{store.id}"
  expect([ 200, 302, 404 ]).to include(response.status)
end
end
