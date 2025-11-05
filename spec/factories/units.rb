# spec/factories/units.rb

FactoryBot.define do
  factory :unit do
    sequence(:name) { |n| "単位#{n}" }
    category { :production }
    description { "テスト用の単位説明" }
    association :user

    trait :production do
      category { :production }
    end

    trait :ordering do
      category { :ordering }
    end
  end
end
