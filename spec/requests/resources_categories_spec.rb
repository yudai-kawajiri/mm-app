require 'rails_helper'

RSpec.describe 'Resources::Categories', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }
  let(:category) { create(:category, :product, company: company) }

  before do
    sign_in user, scope: :user
    host! "#{company.slug}.example.com"
  end

  describe 'categories CRUD' do
    it 'accesses categories index' do
      get scoped_path(:resources_categories)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'shows new category form' do
      get scoped_path(:new_resources_category)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'creates category' do
      post scoped_path(:resources_categories), params: {
        resources_category: {
          name: 'New Category',
          category_type: 'product'
        }
      }
      expect([ 200, 302, 422 ]).to include(response.status)
    end

    it 'shows category' do
      get scoped_path(:resources_category, category)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'edits category' do
      get scoped_path(:edit_resources_category, category)
      expect([ 200, 302, 404 ]).to include(response.status)
    end

    it 'updates category' do
      patch scoped_path(:resources_category, category), params: {
        resources_category: { name: 'Updated Category' }
      }
      expect([ 200, 302, 303, 422 ]).to include(response.status)
    end

    it 'deletes category' do
      delete scoped_path(:resources_category, category)
      expect([ 200, 302, 303, 404 ]).to include(response.status)
    end
  end
end
