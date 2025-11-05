# spec/models/product_material_spec.rb

require 'rails_helper'

RSpec.describe ProductMaterial, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      product_material = create(:product_material)
      expect(product_material).to be_valid
    end

    it '数量がなければ無効であること' do
      product_material = build(:product_material, quantity: nil)
      product_material.valid?
      expect(product_material.errors[:quantity]).to include('を入力してください')
    end

    it '数量が0以下なら無効であること' do
      product_material = build(:product_material, quantity: 0)
      product_material.valid?
      expect(product_material.errors[:quantity]).to be_present
    end
  end

  describe 'アソシエーション' do
    it '商品に属していること' do
      product_material = create(:product_material)
      expect(product_material.product).to be_present
    end

    it '原材料に属していること' do
      product_material = create(:product_material)
      expect(product_material.material).to be_present
    end

    it '単位に属していること' do
      product_material = create(:product_material)
      expect(product_material.unit).to be_present
    end
  end
end
