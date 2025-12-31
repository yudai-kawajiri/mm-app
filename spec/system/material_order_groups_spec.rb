require 'rails_helper'

RSpec.describe '発注グループ', type: :system do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    driven_by(:rack_test)
    login_as(user, scope: :user)
    Capybara.app_host = "http://#{company.slug}.example.com"
  end

  scenario '発注グループページにアクセスできる' do
    visit scoped_path(:resources_material_order_groups)
    expect([200, 302, 404]).to include(page.status_code)
  end
  
  scenario '新規発注グループを作成できる' do
    visit scoped_path(:new_resources_material_order_group)
    expect([200, 302, 404]).to include(page.status_code)
  end
end
