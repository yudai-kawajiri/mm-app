require 'rails_helper'

RSpec.describe "application_requests/new.html.erb", type: :view do
  it "renders" do
    assign(:application_request, ApplicationRequest.new)
    render
    expect(rendered).to match(//)
  end
end
