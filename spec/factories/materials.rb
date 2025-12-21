# spec/factories/materials.rb

FactoryBot.define do
  factory :material, class: 'Resources::Material' do
    association :company
    sequence(:name) { |n| "原材料#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "げんざいりょう#{digits.join}"
    end
    measurement_type { "weight" }
    association :user
    association :category, factory: :category, category_type: :material
    association :unit_for_product, factory: :unit, category: :production
    association :unit_for_order, factory: :unit, category: :ordering
    default_unit_weight { 100 }
    unit_weight_for_order { 1000 }
    description { "テスト用の原材料概要" }
  end
end
