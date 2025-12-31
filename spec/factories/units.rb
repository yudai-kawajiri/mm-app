# spec/factories/units.rb

FactoryBot.define do
  factory :unit, class: 'Resources::Unit' do
    sequence(:name) { |n| "単位#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "たんい#{digits.join}"
    end
    category { :production }
    description { "テスト用の単位概要" }
    
    association :user
    
    # user が指定された場合は user.company を使う
    after(:build) do |unit, evaluator|
      # Company を設定（user から取得または新規作成）
      unit.company ||= unit.user&.company || create(:company)
      
      # Store は optional（明示的に指定された場合のみ設定）
      # unit.store ||= ... は削除（optional: true なので不要）
    end

    trait :production do
      category { :production }
    end

    trait :ordering do
      category { :ordering }
    end
  end
end
