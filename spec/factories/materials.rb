# spec/factories/materials.rb

FactoryBot.define do
  factory :material do
    sequence(:name) { |n| "原材料#{n}" }
    association :user
    association :category, factory: :category, category_type: :material
    association :unit_for_product, factory: :unit, category: :production
    association :unit_for_order, factory: :unit, category: :ordering
    default_unit_weight { 100 }
    unit_weight_for_order { 1000 }
    description { "テスト用の原材料説明" }
  end
end
