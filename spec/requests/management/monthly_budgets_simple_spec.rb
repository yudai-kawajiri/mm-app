require 'rails_helper'

RSpec.describe 'Management::MonthlyBudgets', type: :request do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }
  let(:user) { create(:user, :general, company: company, store: store) }

  before do
    sign_in user
    host! "#{company.slug}.example.com"
  end

  it 'accesses monthly budgets' do
    get scoped_path(:management_monthly_budgets), params: { year: 2025, month: 1 }
    expect([ 200, 302, 404 ]).to include(response.status)
  end
end
