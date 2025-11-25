# spec/factories/plans.rb

FactoryBot.define do
  factory :plan, class: 'Resources::Plan' do
    sequence(:name) { |n| "製造計画#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "せいぞうけいかく#{digits.join}"
    end
    association :user
    association :category, factory: :category, category_type: :plan
    status { :draft }
    description { "テスト用の製造計画概要" }

    trait :draft do
      status { :draft }
    end

    trait :active do
      status { :active }
    end

    trait :completed do
      status { :completed }
    end
  end
end
