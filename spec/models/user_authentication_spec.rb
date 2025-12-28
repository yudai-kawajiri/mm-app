require 'rails_helper'

RSpec.describe User, type: :model do
  let(:company) { create(:company) }
  let(:store) { create(:store, company: company) }

  describe '認証メソッド' do
    it 'approved? returns boolean' do
      user = create(:user, :general, company: company, approved: true)
      expect(user.approved?).to be true
    end

    it 'active_for_authentication? checks approval' do
      user = create(:user, :general, company: company, approved: true)
      expect(user.active_for_authentication?).to be_truthy
    end

    it 'can_manage_company? checks admin role' do
      admin = create(:user, :company_admin, company: company)
      expect(admin.can_manage_company?).to be true
    end

    it 'can_manage_store? checks store access' do
      user = create(:user, :store_admin, company: company, store: store)
      expect(user.can_manage_store?(store)).to be true
    end

    it 'accessible_companies returns companies' do
      user = create(:user, :general, company: company)
      expect(user.accessible_companies).to be_present
    end

    it 'accessible_stores returns stores' do
      user = create(:user, :general, company: company, store: store)
      expect(user.accessible_stores).to be_present
    end
  end

  describe 'roles' do
    it 'roles_i18n_custom returns hash' do
      expect(User.roles_i18n_custom).to be_a(Hash)
    end
  end
end
