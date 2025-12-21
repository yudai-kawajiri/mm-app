FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:subdomain) { |n| "company-#{n}" }
    # plan カラムは存在しないので削除
    # active カラムも存在しない可能性があるので、確認後に追加
  end
end
