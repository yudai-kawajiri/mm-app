require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      contact = Contact.new
      contact.valid?
      expect(contact.errors[:name]).to be_present
    end

    it 'validates presence of email' do
      contact = Contact.new
      contact.valid?
      expect(contact.errors[:email]).to be_present
    end

    it 'validates presence of message' do
      contact = Contact.new
      contact.valid?
      expect(contact.errors[:message]).to be_present
    end

    it 'validates email format' do
      contact = Contact.new(name: 'Test', email: 'invalid', message: 'Test')
      contact.valid?
      expect(contact.errors[:email]).to be_present
    end

    it 'accepts valid email' do
      contact = Contact.new(name: 'Test', email: 'test@example.com', message: 'Test')
      contact.valid?
      expect(contact.errors[:email]).to be_empty
    end
  end
end
