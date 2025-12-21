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
      expect(user.errors[:email]).to include('はすでに存在します')
    end

    it 'パスワードが6文字未満は無効であること' do
      user = build(:user, password: '12345', password_confirmation: '12345')
      user.valid?
      expect(user.errors[:password]).to include('は6文字以上で入力してください')
    end
  end

  describe 'enum' do
    it 'roleがgeneralであること' do
      user = create(:user, :general)
      expect(user.role).to eq('general')
      expect(user.general?).to be true
    end

    it 'roleがsuper_adminであること' do
      user = create(:user, :super_admin)
      expect(user.role).to eq('super_admin')
      expect(user.super_admin?).to be true
    end
  end

  describe 'デフォルト値' do
    it '新規ユーザーのroleはgeneralであること' do
      user = create(:user)
      expect(user.role).to eq('general')
    end
  end
end
