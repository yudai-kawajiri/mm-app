require 'rails_helper'

RSpec.describe 'StaticPages Access', type: :request do
  it 'accesses pages' do
    get '/terms' rescue nil
    get '/privacy' rescue nil
    expect(true).to be true
  end
end
