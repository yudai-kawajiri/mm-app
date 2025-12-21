# spec/factories/products.rb

FactoryBot.define do
  factory :product, class: 'Resources::Product' do
    association :company
    sequence(:name) { |n| "商品#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "しょうひん#{digits.join}"
    end
    sequence(:item_number) { |n| n.to_s.rjust(4, '0') }
    association :user
    association :category, factory: :category, category_type: :product
    price { 1000 }
    status { :selling }
    description { "テスト用の商品概要" }

    trait :draft do
      status { :draft }
    end

    trait :selling do
      status { :selling }
    end

    trait :discontinued do
      status { :discontinued }
    end
  end
end
