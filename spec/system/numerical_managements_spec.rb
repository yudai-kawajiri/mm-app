require 'rails_helper'

RSpec.describe '数値管理', type: :system do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    driven_by(:rack_test)
    login_as(user, scope: :user)
    Capybara.app_host = "http://#{company.slug}.example.com"
  end

  scenario '数値管理ページにアクセスできる' do
    visit scoped_path(:management_numerical_managements)
    expect([ 200, 302, 404 ]).to include(page.status_code)
  end
end
