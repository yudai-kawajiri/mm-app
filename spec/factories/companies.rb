FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:slug) { |n| "company-#{n}" }
    sequence(:email) { |n| "company#{n}@example.com" }
  end
end
