# spec/factories/plans.rb

FactoryBot.define do
  factory :plan do
    sequence(:name) { |n| "製造計画#{n}" }
    association :user
    association :category, factory: :category, category_type: :plan
    status { :draft }
    description { "テスト用の製造計画概要" }

    trait :draft do
      status { :draft }
    end

    trait :active do
      status { :active }
    end

    trait :completed do
      status { :completed }
    end
  end
end
