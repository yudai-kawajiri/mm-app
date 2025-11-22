# spec/factories/monthly_budgets.rb

FactoryBot.define do
  factory :monthly_budget do
    association :user
    budget_month { Date.current.beginning_of_month }
    target_amount { 1000000 }
    description { "テスト用の予算メモ" }

    trait :this_month do
      budget_month { Date.current.beginning_of_month }
    end

    trait :last_month do
      budget_month { 1.month.ago.beginning_of_month }
    end

    trait :next_month do
      budget_month { 1.month.since.beginning_of_month }
    end
  end
end
