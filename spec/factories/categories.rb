# spec/factories/categories.rb

FactoryBot.define do
  factory :category, class: 'Resources::Category' do
    transient do
      user { nil }
    end

    company { user&.company || create(:company) }
    sequence(:name) { |n| "カテゴリ#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "かてごり#{digits.join}"
    end
    category_type { :material }
    description { "テスト用のカテゴリ概要" }

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
