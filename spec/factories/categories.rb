# spec/factories/categories.rb

FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "カテゴリー#{n}" }
    category_type { :material }
    description { "テスト用のカテゴリー説明" }
    association :user

    trait :material do
      category_type { :material }
    end

    trait :product do
      category_type { :product }
    end

    trait :plan do
      category_type { :plan }
    end
  end
end
