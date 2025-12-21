FactoryBot.define do
  factory :store do
    association :company
    name { "MyString" }
    code { "MyString" }
    address { "MyText" }
    active { false }
  end
end
