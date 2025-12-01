# spec/models/unit_spec.rb

require 'rails_helper'

RSpec.describe Resources::Unit, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      unit = create(:unit)
      expect(unit).to be_valid
    end

    it '名前がなければ無効であること' do
      unit = build(:unit, name: nil)
      unit.valid?
      expect(unit.errors[:name]).to include('を入力してください')
    end

    it 'カテゴリ―がなければ無効であること' do
      unit = build(:unit, category: nil)
      unit.valid?
      expect(unit.errors[:category]).to include('を入力してください')
    end
  end

  describe 'enum' do
    it 'categoryがproductionであること' do
      unit = create(:unit, :production)
      expect(unit.category).to eq('production')
      expect(unit.production?).to be true
    end

    it 'categoryがorderingであること' do
      unit = create(:unit, :ordering)
      expect(unit.category).to eq('ordering')
      expect(unit.ordering?).to be true
    end
  end

  describe 'アソシエーション' do
    it 'ユーザーに属していること' do
      unit = create(:unit)
      expect(unit.user).to be_present
    end
  end
end
