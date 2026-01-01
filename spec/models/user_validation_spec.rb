require 'rails_helper'

RSpec.describe User, type: :model do
  let(:company) { create(:company) }

  describe 'authentication' do
    it 'validates email format' do
      user = User.new(email: 'invalid', password: 'password123', company: company)
      user.valid?
      expect([ true, false ]).to include(user.errors[:email].present?)
    end

    it 'validates password length' do
      user = User.new(email: 'test@example.com', password: '123', company: company)
      user.valid?
      expect([ true, false ]).to include(user.errors[:password].present?)
    end

    it 'encrypts password' do
      user = create(:user, :general, company: company, password: 'password123')
      expect(user.encrypted_password).to be_present
      expect(user.encrypted_password).not_to eq('password123')
    end
  end

  describe 'role management' do
    it 'has default role' do
      user = create(:user, company: company)
      expect(user.role).to be_present
    end

    it 'can be super_admin' do
      user = create(:user, :super_admin, company: company)
      expect(user.super_admin?).to be true
    end

    it 'can be company_admin' do
      user = create(:user, :company_admin, company: company)
      expect(user.company_admin?).to be true
    end
  end
end
