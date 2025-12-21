# spec/factories/units.rb

FactoryBot.define do
  factory :unit, class: 'Resources::Unit' do
    association :company
    sequence(:name) { |n| "単位#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "たんい#{digits.join}"
    end
    category { :production }
    description { "テスト用の単位概要" }
    association :user

    trait :production do
      category { :production }
    end

    trait :ordering do
      category { :ordering }
    end
  end
end
