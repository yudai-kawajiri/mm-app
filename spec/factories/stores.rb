FactoryBot.define do
  factory :store do
    association :company
    sequence(:name) { |n| "Store #{n}" }
    sequence(:code) { |n| "STORE#{n.to_s.rjust(3, '0')}" }
    address { "MyText" }
    active { false }
  end
end
