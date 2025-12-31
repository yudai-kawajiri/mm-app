# spec/factories/plan_schedules.rb

FactoryBot.define do
  factory :plan_schedule, class: 'Planning::PlanSchedule' do
    association :user
    transient do
      company { user&.company || create(:company) }
    end

    association :plan, factory: :plan, strategy: :build
    before(:create) do |plan_schedule, evaluator|
      plan_schedule.company ||= evaluator.company
      plan_schedule.plan ||= create(:plan, user: plan_schedule.user, company: evaluator.company)
    end
    scheduled_date { Date.current }
    actual_revenue { nil }

    status { :scheduled }
    description { "テスト用の計画スケジュール説明" }

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
