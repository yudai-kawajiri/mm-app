require 'rails_helper'

RSpec.describe "application_requests/accept.html.erb", type: :view do
  it "renders" do
    company = create(:company)
    assign(:application_request, ApplicationRequest.new(company: company))
    render
    expect(rendered).to match(//)
  end
end
