# spec/factories/plans.rb

FactoryBot.define do
  factory :plan, class: 'Resources::Plan' do
    sequence(:name) { |n| "製造計画#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "せいぞうけいかく#{digits.join}"
    end
    status { :draft }
    description { "テスト用の製造計画概要" }
    
    association :user
    
    # user が指定された場合は user.company を使う
    after(:build) do |plan, evaluator|
      # Company を設定（user から取得または新規作成）
      plan.company ||= plan.user&.company || create(:company)
      
      # Category を設定（同じ company の plan カテゴリーを使用）
      unless plan.category
        plan.category = create(:category,
                               category_type: :plan,
                               company: plan.company,
                               user: plan.user)
      end
    end

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
