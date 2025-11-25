# spec/factories/plan_products.rb

FactoryBot.define do
  factory :plan_product, class: 'Planning::PlanProduct' do
    association :plan, factory: :plan
    association :product, factory: :product
    production_count { 100 }

    trait :with_high_production do
      production_count { 1000 }
    end

    trait :with_low_production do
      production_count { 10 }
    end
  end
end
