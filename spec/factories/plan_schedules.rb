# spec/factories/plan_schedules.rb

FactoryBot.define do
  factory :plan_schedule do
    association :user
    association :plan
    scheduled_date { Date.current }
    planned_revenue { 50000 }
    actual_revenue { nil }
    status { :scheduled }
    description { "テスト用の計画スケジュールメモ" }

    trait :scheduled do
      status { :scheduled }
      actual_revenue { nil }
    end

    trait :completed do
      status { :completed }
      actual_revenue { 48000 }
    end

    trait :today do
      scheduled_date { Date.current }
    end

    trait :yesterday do
      scheduled_date { Date.yesterday }
    end
  end
end
