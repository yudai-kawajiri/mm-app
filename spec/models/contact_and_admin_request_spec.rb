require 'rails_helper'

RSpec.describe 'Contact and AdminRequest', type: :model do
  describe Contact do
    it 'can be created with attributes' do
      contact = Contact.new(
        name: 'Test User',
        email: 'test@example.com',
        message: 'Test message'
      )
      expect(contact).to be_a(Contact)
    end

    it 'has name, email, message attributes' do
      contact = Contact.new
      expect(contact).to respond_to(:name)
      expect(contact).to respond_to(:email)
      expect(contact).to respond_to(:message)
    end
  end

  describe AdminRequest do
    let(:company) { create(:company) }
    let(:user) { create(:user, :general, company: company) }

    it 'belongs to user' do
      request = AdminRequest.new(user: user, company: company)
      expect(request.user).to eq(user)
    end

    it 'belongs to company' do
      request = AdminRequest.new(user: user, company: company)
      expect(request.company).to eq(company)
    end

    it 'has status enum' do
      expect(AdminRequest).to respond_to(:statuses)
    end
  end
end
