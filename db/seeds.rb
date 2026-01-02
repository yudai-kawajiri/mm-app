# db/seeds.rb

# # Seeds が既に実行されているかチェック
# if Rails.env.production? && Company.exists?(slug: 'admin')
#   puts "=========================================="
#   puts "Seeds は既に実行済みです。スキップします。"
#   puts "=========================================="
#   exit 0
# end

puts "=========================================="
puts "シード処理を開始します..."
puts "=========================================="

# ====================
# 1. 管理用会社の作成
# ====================
admin_company = Company.find_or_create_by!(slug: 'admin') do |c|
  c.name = 'システム管理'
  c.email = ENV['ADMIN_COMPANY_EMAIL'] || 'admin@mm-app-manage.com'
end
puts " 会社作成完了: #{admin_company.name}"

# ====================
# 2. システム管理者アカウント（本番用・非公開）
# ====================
admin_email = ENV['ADMIN_EMAIL'] || 'admin@example.com'
admin_password = ENV['ADMIN_PASSWORD'] || 'ChangeMe123!'

admin_user = User.find_or_create_by!(email: admin_email) do |u|
  u.password = admin_password
  u.password_confirmation = admin_password
  u.name = ENV['ADMIN_NAME'] || 'システム管理者'
  u.role = :super_admin
  u.company = admin_company
  u.approved = true
end

admin_user.update!(
  role: :super_admin,
  approved: true,
  company: admin_company
)

puts " システム管理者作成完了: #{admin_user.email}"
puts "   Role: #{admin_user.role}"
puts "   Super Admin?: #{admin_user.super_admin?}"

# ====================
# 3. ポートフォリオ閲覧者アカウント（転職用・公開OK）
# ====================
portfolio_email = ENV['PORTFOLIO_EMAIL'] || 'admin@mm-app-manage.com'
portfolio_password = ENV['PORTFOLIO_PASSWORD'] || 'Portfolio2026!'

portfolio_admin = User.find_or_create_by!(email: portfolio_email) do |u|
  u.password = portfolio_password
  u.password_confirmation = portfolio_password
  u.name = ENV['PORTFOLIO_NAME'] || 'ポートフォリオ閲覧者（システム管理者）'
  u.role = :super_admin
  u.company = admin_company
  u.approved = true
end

portfolio_admin.update!(
  role: :super_admin,
  approved: true,
  company: admin_company
)

puts " ポートフォリオ閲覧者作成完了: #{portfolio_admin.email}"

# ====================
# 4. ポートフォリオ用テストデータ（魚屋の寿司）
# ====================
puts "\n=========================================="
puts "ポートフォリオ用テストデータを作成します..."
puts "=========================================="

# 会社の作成
uoya_company_slug = ENV['TEST_COMPANY_SLUG'] || 'uoya-sushi'
uoya_company_name = ENV['TEST_COMPANY_NAME'] || '魚屋の寿司株式会社'
uoya_company_email = ENV['TEST_COMPANY_EMAIL'] || 'info@uoya-sushi.test'
uoya_company_phone = ENV['TEST_COMPANY_PHONE'] || '0312345678'

uoya_company = Company.find_or_create_by!(slug: uoya_company_slug) do |c|
  c.name = uoya_company_name
  c.email = uoya_company_email
  c.phone = uoya_company_phone
end
puts " 会社作成完了: #{uoya_company.name}"

# 店舗の作成
store_code = ENV['TEST_STORE_CODE'] || 'MAIN'
store_name = ENV['TEST_STORE_NAME'] || '魚屋の寿司 本店'
invitation_code = ENV['TEST_STORE_INVITATION_CODE'] || 'MAIN2026'

main_store = Store.find_or_create_by!(company: uoya_company, code: store_code) do |s|
  s.name = store_name
  s.invitation_code = invitation_code
  s.active = true
end
puts " 店舗作成完了: #{main_store.name}"
puts "   招待コード: #{main_store.invitation_code}"

# テストアカウント共通パスワード
test_password = ENV['TEST_ACCOUNT_PASSWORD'] || 'Test2026!'

# 会社管理者の作成
company_admin_email = ENV['COMPANY_ADMIN_EMAIL'] || 'company-admin@uoya-sushi.test'
company_admin_name = ENV['COMPANY_ADMIN_NAME'] || '会社管理者'

company_admin = User.find_or_create_by!(email: company_admin_email) do |u|
  u.password = test_password
  u.password_confirmation = test_password
  u.name = company_admin_name
  u.role = :company_admin
  u.company = uoya_company
  u.approved = true
end

company_admin.update!(
  role: :company_admin,
  approved: true,
  company: uoya_company
)

puts " 会社管理者作成完了: #{company_admin.email}"

# 店舗管理者の作成
store_admin_email = ENV['STORE_ADMIN_EMAIL'] || 'store-admin@uoya-sushi.test'
store_admin_name = ENV['STORE_ADMIN_NAME'] || '店舗管理者'

store_admin = User.find_or_create_by!(email: store_admin_email) do |u|
  u.password = test_password
  u.password_confirmation = test_password
  u.name = store_admin_name
  u.role = :store_admin
  u.company = uoya_company
  u.store = main_store
  u.approved = true
end

store_admin.update!(
  role: :store_admin,
  approved: true,
  company: uoya_company,
  store: main_store
)

puts " 店舗管理者作成完了: #{store_admin.email}"

# 一般スタッフの作成
staff_email = ENV['STAFF_EMAIL'] || 'staff@uoya-sushi.test'
staff_name = ENV['STAFF_NAME'] || '一般スタッフ'

staff_user = User.find_or_create_by!(email: staff_email) do |u|
  u.password = test_password
  u.password_confirmation = test_password
  u.name = staff_name
  u.role = :general
  u.company = uoya_company
  u.store = main_store
  u.approved = true
end

staff_user.update!(
  role: :general,
  approved: true,
  company: uoya_company,
  store: main_store
)

puts " 一般スタッフ作成完了: #{staff_user.email}"

puts "\n=========================================="
puts "シード処理完了 "
puts "=========================================="
