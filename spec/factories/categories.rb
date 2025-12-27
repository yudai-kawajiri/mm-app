# spec/factories/categories.rb

FactoryBot.define do
  factory :category, class: 'Resources::Category' do
    association :company
    sequence(:name) { |n| "カテゴリー#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "かてごりー#{digits.join}"
    end
    category_type { :material }
    description { "テスト用のカテゴリー概要" }
    association :user

    trait :material do
      category_type { :material }
    end

    trait :product do
      category_type { :product }
    end

    trait :plan do
      reading { 'けいかくかてごり' }
    category_type { :plan }
    end
  end
end
