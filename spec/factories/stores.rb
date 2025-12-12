FactoryBot.define do
  factory :store do
    tenant { nil }
    name { "MyString" }
    code { "MyString" }
    address { "MyText" }
    active { false }
  end
end
