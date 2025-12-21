# spec/factories/monthly_budgets.rb

FactoryBot.define do
  factory :monthly_budget, class: 'Management::MonthlyBudget' do
    association :company
    sequence(:budget_month) { |n| (Date.current.beginning_of_month + n.months) }
    target_amount { 1000000 }
    description { "テスト用の予算メモ" }

    trait :with_user do
      association :user
    end

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
