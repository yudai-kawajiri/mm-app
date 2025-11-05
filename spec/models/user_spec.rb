# spec/models/user_spec.rb

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      user = build(:user)
      expect(user).to be_valid
    end

    it '名前がなければ無効であること' do
      user = build(:user, name: nil)
      user.valid?
      expect(user.errors[:name]).to include('を入力してください')
    end

    it 'メールアドレスがなければ無効であること' do
      user = build(:user, email: nil)
      user.valid?
      expect(user.errors[:email]).to include('を入力してください')
    end

    it '重複したメールアドレスは無効であること' do
      create(:user, email: 'test@example.com')
      user = build(:user, email: 'test@example.com')
      user.valid?
      expect(user.errors[:email]).to include('は既に使用されています')
    end

    it 'パスワードが6文字未満は無効であること' do
      user = build(:user, password: '12345', password_confirmation: '12345')
      user.valid?
      expect(user.errors[:password]).to include('6 文字以上で入力してください') 
    end
  end

  describe 'enum' do
    it 'roleがstaffであること' do
      user = create(:user, :staff)
      expect(user.role).to eq('staff')
      expect(user.staff?).to be true
    end

    it 'roleがadminであること' do
      user = create(:user, :admin)
      expect(user.role).to eq('admin')
      expect(user.admin?).to be true
    end
  end

  describe 'デフォルト値' do
    it '新規ユーザーのroleはstaffであること' do
      user = create(:user)
      expect(user.role).to eq('staff')
    end
  end
end
