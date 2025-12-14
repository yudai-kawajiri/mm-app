FactoryBot.define do
  factory :application_request do
    company_name { "MyString" }
    company_email { "MyString" }
    company_phone { "MyString" }
    admin_name { "MyString" }
    admin_email { "MyString" }
    status { 1 }
    invitation_token { "MyString" }
    invitation_sent_at { "2025-12-14 22:49:07" }
    tenant_id { 1 }
  end
end
