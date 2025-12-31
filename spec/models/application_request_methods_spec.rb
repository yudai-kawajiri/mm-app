require 'rails_helper'

RSpec.describe ApplicationRequest, type: :model do
  it 'has status enum' do
    expect(ApplicationRequest).to respond_to(:statuses)
  end
end
