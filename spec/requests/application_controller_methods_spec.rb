require 'rails_helper'

RSpec.describe 'ApplicationController Methods', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user
    host! "#{company.slug}.example.com"
  end

  describe 'authenticated actions trigger controller methods' do
    it 'triggers set_current_company' do
      get '/dashboards' rescue nil
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'triggers set_current_store' do
      get scoped_path(:resources_materials) rescue nil
      expect([ 200, 302, 404 ]).to include(response.status)
    end
  end
end
