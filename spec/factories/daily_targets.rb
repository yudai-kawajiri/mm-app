# spec/factories/daily_targets.rb

FactoryBot.define do
  factory :daily_target do
    association :user
    association :monthly_budget
    target_date { Date.current }
    target_amount { 30000 }
    note { "テスト用の日別目標メモ" }

    trait :today do
      target_date { Date.current }
    end

    trait :yesterday do
      target_date { Date.yesterday }
    end

    trait :tomorrow do
      target_date { Date.tomorrow }
    end
  end
end
