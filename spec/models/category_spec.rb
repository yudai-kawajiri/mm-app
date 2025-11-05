# spec/models/category_spec.rb

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      category = create(:category)  # build → create に変更
      expect(category).to be_valid
    end

    it '名前がなければ無効であること' do
      category = build(:category, name: nil)
      category.valid?
      expect(category.errors[:name]).to include('を入力してください')
    end

    it 'category_typeがなければ無効であること' do
      category = build(:category, category_type: nil)
      category.valid?
      expect(category.errors[:category_type]).to include('を入力してください')
    end

    it '同じcategory_type内で名前が重複していれば無効であること' do
      create(:category, name: 'テストカテゴリー', category_type: :material)
      category = build(:category, name: 'テストカテゴリー', category_type: :material)
      category.valid?
      expect(category.errors[:name]).to include('は既に使用されています')  # 「は既に存在します」→「は既に使用されています」
    end

    it '異なるcategory_typeであれば同じ名前でも有効であること' do
      user = create(:user)  # ユーザーを明示的に作成
      create(:category, name: 'テストカテゴリー', category_type: :material, user: user)
      category = build(:category, name: 'テストカテゴリー', category_type: :product, user: user)
      expect(category).to be_valid
    end
  end

  describe 'enum' do
    it 'category_typeがmaterialであること' do
      category = create(:category, :material)
      expect(category.category_type).to eq('material')
      expect(category.material?).to be true
    end

    it 'category_typeがproductであること' do
      category = create(:category, :product)
      expect(category.category_type).to eq('product')
      expect(category.product?).to be true
    end

    it 'category_typeがplanであること' do
      category = create(:category, :plan)
      expect(category.category_type).to eq('plan')
      expect(category.plan?).to be true
    end
  end
end
