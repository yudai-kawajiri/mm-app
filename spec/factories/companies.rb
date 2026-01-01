FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:slug) { |n| "company-#{n}" }
    sequence(:code) { |n| "CODE#{n.to_s.rjust(4, '0')}" }
  end
end
