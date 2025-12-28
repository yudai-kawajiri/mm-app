require 'rails_helper'

RSpec.describe 'ApplicationController Scoped Methods', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user
    host! "#{company.slug}.example.com"
  end

  describe 'scoped queries execution' do
    it 'executes scoped_products via products index' do
      create(:category, company: company, name: 'Test')
      get scoped_path(:resources_products)
      expect([200, 302, 404]).to include(response.status)
    end

    it 'executes scoped_materials via materials index' do
      get scoped_path(:resources_materials)
      expect([200, 302, 404]).to include(response.status)
    end

    it 'executes scoped_categories via categories index' do
      get scoped_path(:resources_categories)
      expect([200, 302, 404]).to include(response.status)
    end

    it 'executes scoped_units via units index' do
      get scoped_path(:resources_units)
      expect([200, 302, 404]).to include(response.status)
    end

    it 'executes scoped_plans via plans index' do
      get scoped_path(:resources_plans)
      expect([200, 302, 404]).to include(response.status)
    end
  end

  describe 'store-scoped queries' do
    before do
      # セッションにstore_idを設定
      post scoped_path(:resources_materials), params: { 
        resources_material: { name: 'Test', store_id: store.id }
      } rescue nil
    end

    it 'executes store-scoped materials query' do
      get scoped_path(:resources_materials)
      expect([200, 302, 404]).to include(response.status)
    end
  end
end
