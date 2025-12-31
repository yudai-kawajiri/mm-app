# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Resources::MaterialOrderGroup, type: :model do
  let(:user) { create(:user) }
  let(:material_order_group) { create(:material_order_group, user: user) }

  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      expect(material_order_group).to be_valid
    end

    it 'nameが必須であること' do
      material_order_group.name = nil
      expect(material_order_group).not_to be_valid
      expect(material_order_group.errors[:name]).to include('を入力してください')
    end

    it 'nameが一意であること' do
      create(:material_order_group, name: 'マグロ類', user: user)
      duplicate_group = build(:material_order_group, name: 'マグロ類', user: user)
      expect(duplicate_group).not_to be_valid
      expect(duplicate_group.errors[:name]).to include('はすでに存在します')
    end

    it 'readingが存在すること' do
      expect(material_order_group.reading).to be_present
    end
  end

  describe '関連付け' do
    it 'userに所属すること' do
      expect(material_order_group.user).to eq(user)
    end

    it '複数のmaterialsを持つこと' do
      material1 = create(:material, order_group: material_order_group, user: user)
      material2 = create(:material, order_group: material_order_group, user: user)

      expect(material_order_group.materials).to include(material1, material2)
      expect(material_order_group.materials.count).to eq(2)
    end

    it 'materialsが紐付いている場合は削除できないこと' do
      create(:material, order_group: material_order_group, user: user)

      expect { material_order_group.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end

  describe 'スコープ' do
    before do
      @group1 = create(:material_order_group, name: 'Aグループ', reading: 'えぐるぷ', user: user, created_at: 2.days.ago)
      @group2 = create(:material_order_group, name: 'Bグループ', reading: 'びぐるぷ', user: user, created_at: 1.day.ago)
    end

    it 'orderedスコープで名前順（reading順）にソートされること' do
      expect(Resources::MaterialOrderGroup.ordered).to eq([ @group1, @group2 ])
    end

    it 'for_indexスコープで新しい順にソートされること' do
      expect(Resources::MaterialOrderGroup.for_index).to eq([ @group2, @group1 ])
    end
  end

  describe 'Copyable機能' do
    it 'コピー可能であること' do
      expect(material_order_group).to respond_to(:create_copy)
    end

    it 'コピー時にユニーク制約が適用されること' do
      copy = material_order_group.create_copy(user: user)
      expect(copy.name).to match(/#{material_order_group.name}.*コピー/)
      expect(copy).to be_persisted
    end
  end

  describe 'PaperTrail' do
    it '変更履歴を記録すること' do
      PaperTrail.request.whodunnit = user.id
      material_order_group.update(name: '更新後の名前')
      expect(material_order_group.versions.count).to be > 0
    end
  end
end
