# spec/models/material_spec.rb

require 'rails_helper'

RSpec.describe Resources::Material, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      material = create(:material)
      expect(material).to be_valid
    end

    it '名前がなければ無効であること' do
      material = build(:material, name: nil)
      material.valid?
      expect(material.errors[:name]).to include('を入力してください')
    end

    it '同じカテゴリ―内で名前が重複していれば無効であること' do
      category = create(:category, :material)
      user = create(:user)
      create(:material, name: 'テスト原材料', category: category, user: user)
      material = build(:material, name: 'テスト原材料', category: category, user: user)
      material.valid?
      expect(material.errors[:name]).to include('はすでに存在します')
    end

    it '異なるカテゴリ―であれば同じ名前でも有効であること' do
      category1 = create(:category, :material)
      category2 = create(:category, :material)
      user = create(:user)
      create(:material, name: 'テスト原材料', category: category1, user: user)
      material = build(:material, name: 'テスト原材料', category: category2, user: user)
      expect(material).to be_valid
    end

    it '発注単位の重量がなければ無効であること' do
      material = build(:material, unit_weight_for_order: nil)
      material.valid?
      expect(material.errors[:unit_weight_for_order]).to include('を入力してください')
    end

    it '発注単位の重量が0以下なら無効であること' do
      material = build(:material, unit_weight_for_order: 0)
      material.valid?
      expect(material.errors[:unit_weight_for_order]).to include('は0より大きい値にしてください')
    end

    it 'デフォルト重量が負の値なら無効であること' do
      material = build(:material, default_unit_weight: -1)
      material.valid?
      expect(material.errors[:default_unit_weight]).to be_present
    end

    it 'デフォルト重量がnilでも有効であること' do
      material = create(:material, default_unit_weight: nil)
      expect(material).to be_valid
    end
  end

  describe 'アソシエーション' do
    it 'カテゴリに属していること' do
      material = create(:material)
      expect(material.category).to be_present
    end

    it '商品単位を持つこと' do
      material = create(:material)
      expect(material.unit_for_product).to be_present
    end

    it '発注単位を持つこと' do
      material = create(:material)
      expect(material.unit_for_order).to be_present
    end
  end

  describe '#order_conversion_type' do
    it '個数ベースの場合は:piecesを返すこと' do
      material = create(:material, measurement_type: 'count', pieces_per_order_unit: 50, unit_weight_for_order: 1000)
      expect(material.order_conversion_type).to eq(:count)
    end

    it '重量ベースの場合は:weightを返すこと' do
      material = create(:material, measurement_type: 'weight', pieces_per_order_unit: nil, unit_weight_for_order: 1000)
      expect(material.order_conversion_type).to eq(:weight)
    end

    it '発注単位の重量が0の場合は:noneを返すこと' do
      material = build(:material, measurement_type: 'weight', pieces_per_order_unit: nil, unit_weight_for_order: 0)
      expect(material.order_conversion_type).to eq(:weight)
    end
  end
end
