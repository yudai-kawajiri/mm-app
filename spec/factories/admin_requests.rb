FactoryBot.define do
  factory :admin_request do
    company { nil }
    user { nil }
    store { nil }
    request_type { 1 }
    status { 1 }
    message { "MyText" }
    rejection_reason { "MyText" }
    approved_by_id { "" }
    approved_at { "2025-12-14 11:31:56" }
  end
end
