# spec/factories/product_materials.rb

FactoryBot.define do
  factory :product_material do
    association :product
    association :material
    association :unit
    quantity { 100 }
    unit_weight { 50 }
  end
end
