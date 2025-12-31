# spec/factories/material_order_groups.rb

FactoryBot.define do
  factory :material_order_group, class: 'Resources::MaterialOrderGroup' do
    association :company
    sequence(:name) { |n| "発注グループ#{n}" }
    sequence(:reading) do |n|
      hiragana_nums = %w[ぜろ いち に さん よん ご ろく なな はち きゅう]
      digits = n.to_s.chars.map { |d| hiragana_nums[d.to_i] }
      "はっちゅうぐるぷ#{digits.join}"
    end
    association :user
  end
end
