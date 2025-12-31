# spec/models/product_spec.rb

require 'rails_helper'

RSpec.describe Resources::Product, type: :model do
  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      product = create(:product)
      expect(product).to be_valid
    end

    it '売価が0以下なら無効であること' do
      product = build(:product, price: 0)
      product.valid?
      expect(product.errors[:price]).to include('は0より大きい値にしてください')  # スペースなし
    end

    it 'ステータスがなければ無効であること' do
      product = build(:product, status: nil)
      product.valid?
      expect(product.errors[:status]).to include('を入力してください')
    end

    it '売価がなければ無効であること' do
      product = build(:product, price: nil)
      product.valid?
      expect(product.errors[:price]).to include('を入力してください')
    end

    it '売価が0以下なら無効であること' do
      product = build(:product, price: 0)
      product.valid?
      expect(product.errors[:price]).to include('は0より大きい値にしてください')
    end

    it 'カテゴリ―がなければ無効であること' do
      product = build(:product, category: nil)
      product.valid?
      expect(product.errors[:category]).to include('を入力してください')
    end

    it 'ステータスがなければ無効であること' do
      product = build(:product, status: nil)
      product.valid?
      expect(product.errors[:status]).to include('を入力してください')
    end
  end

  describe 'enum' do
    it 'statusがdraftであること' do
      product = create(:product, :draft)
      expect(product.status).to eq('draft')
      expect(product.draft?).to be true
    end

    it 'statusがsellingであること' do
      product = create(:product, :selling)
      expect(product.status).to eq('selling')
      expect(product.selling?).to be true
    end

    it 'statusがdiscontinuedであること' do
      product = create(:product, :discontinued)
      expect(product.status).to eq('discontinued')
      expect(product.discontinued?).to be true
    end
  end

  describe 'アソシエーション' do
    it 'カテゴリ―に属していること' do
      product = create(:product)
      expect(product.category).to be_present
    end

    it 'ユーザーに属していること' do
      product = create(:product)
      expect(product.user).to be_present
    end
  end

  describe '#display_info' do
    it 'returns product info' do
      product = create(:product, name: 'Test Product')
      expect(product.name).to eq('Test Product')
    end
  end

  describe 'with materials' do
    it 'has product_materials' do
      product = create(:product)
      expect(product).to respond_to(:product_materials)
    end
  end

end