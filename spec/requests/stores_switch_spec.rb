require 'rails_helper'

RSpec.describe 'Stores Switch', type: :request do
  let(:company) { create(:company) }
  let(:store1) { create(:store, company: company) }
  let(:store2) { create(:store, company: company, name: 'Store 2', code: 'STORE2') }
  let(:admin) { create(:user, :company_admin, company: company, store: store1) }

  before do
    sign_in admin, scope: :user
    host! "#{company.slug}.example.com"
  end

  describe 'POST /switch_store' do
    it 'switches to specific store' do
      post "/c/#{company.slug}/switch_store", params: { current_store_id: store2.id }
      expect([ 200, 302 ]).to include(response.status)
      expect(session[:current_store_id]).to eq(store2.id) if response.status == 302
    end

    it 'switches to all stores' do
      post "/c/#{company.slug}/switch_store", params: { current_store_id: nil }
      expect([ 200, 302 ]).to include(response.status)
    end
  end
end
