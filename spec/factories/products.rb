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

    after(:build) do |products, evaluator|
      # Company を設定（user から取得または新規作成）
      products.company ||= products.user&.company || create(:company)
      
      # Store は optional（明示的に指定された場合のみ設定）
      # products.store ||= ... は削除（optional: true なので不要）
    end

    trait :selling do
      status { :selling }
    end

    trait :discontinued do
      status { :discontinued }
    end
  end
end
