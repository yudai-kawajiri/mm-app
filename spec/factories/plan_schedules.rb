# spec/factories/plan_schedules.rb

FactoryBot.define do
  factory :plan_schedule, class: 'Planning::PlanSchedule' do
    association :user
    scheduled_date { Date.current }
    actual_revenue { nil }
    
    after(:build) do |plan_schedule|
      # Company を user から取得
      plan_schedule.company ||= plan_schedule.user&.company || create(:company)
      
      # Plan を同じ company/user で作成
      plan_schedule.plan ||= create(:plan, user: plan_schedule.user, company: plan_schedule.company)
    end
    
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
