# spec/factories/users.rb

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :staff }

    trait :admin do
      role { :admin }
    end

    trait :staff do
      role { :staff }
    end
  end
end
