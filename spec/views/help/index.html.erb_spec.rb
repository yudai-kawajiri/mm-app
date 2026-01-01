require 'rails_helper'

RSpec.describe "help/index.html.erb", type: :view do
  it "renders" do
    render
    expect(rendered).to match(//)
  end
end
