FactoryBot.define do
  factory :store do
    company { nil }
    name { "MyString" }
    code { "MyString" }
    address { "MyText" }
    active { false }
  end
end
