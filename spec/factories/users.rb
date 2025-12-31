# spec/factories/users.rb

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :general }
    association :company

    trait :super_admin do
      role { :super_admin }
    end

    trait :company_admin do
      role { :company_admin }
    end

    trait :store_admin do
      role { :store_admin }
    end

    trait :general do
      role { :general }
    end
  end
end
