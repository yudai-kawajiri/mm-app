# spec/factories/products.rb

FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "商品#{n}" }
    sequence(:item_number) { |n| n.to_s.rjust(4, '0') }
    association :category, factory: :category, category_type: :product
    price { 1000 }
    status { :selling }
    description { "テスト用の商品説明" }

    trait :draft do
      status { :draft }
    end

    trait :selling do
      status { :selling }
    end

    trait :discontinued do
      status { :discontinued }
    end
  end
end
