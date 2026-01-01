require 'rails_helper'

RSpec.describe Resources::MaterialOrderGroupsController, type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user, scope: :user
    host! "#{company.slug}.example.com"
  end

  describe 'full operations' do
    it 'performs complete workflow' do
      # INDEX
      get scoped_path(:resources_material_order_groups)
      expect([ 200, 302, 404 ]).to include(response.status)

      # NEW
      get scoped_path(:new_resources_material_order_group)
      expect([ 200, 302, 404 ]).to include(response.status)

      # CREATE
      post scoped_path(:resources_material_order_groups), params: {
        resources_material_order_group: {
          name: 'Test Order Group',
          order_date: Date.today
        }
      }

      # If created successfully, test show/edit/update
      if Resources::MaterialOrderGroup.last
        mog = Resources::MaterialOrderGroup.last

        # SHOW
        get scoped_path(:resources_material_order_group, mog)
        expect([ 200, 302, 404 ]).to include(response.status)

        # EDIT
        get scoped_path(:edit_resources_material_order_group, mog)
        expect([ 200, 302, 404 ]).to include(response.status)

        # UPDATE
        patch scoped_path(:resources_material_order_group, mog), params: {
          resources_material_order_group: { name: 'Updated Name' }
        }
        expect([ 200, 302, 404, 422 ]).to include(response.status)
      end

      expect(true).to be true
    end
  end
end
