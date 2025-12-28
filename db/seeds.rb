puts "===== データベースのシード処理を開始 ====="

# システム管理者用会社（冪等性対応）
admin_company = Company.find_or_create_by!(slug: 'admin') do |c|
  c.name = 'システム管理'
  c.code = 'ADMIN'
end

puts "✓ 会社作成完了: #{admin_company.name}"

# システム管理者（冪等性対応）
admin_user = User.find_or_create_by!(email: 'admin@example.com') do |u|
  u.password = 'password'
  u.password_confirmation = 'password'
  u.name = 'システム管理者'
  u.role = :super_admin
  u.company = admin_company
  u.approved = true
end

puts "✓ システム管理者作成完了: #{admin_user.email}"

# テスト会社（冪等性対応）
test_company = Company.find_or_create_by!(slug: 'test-company') do |c|
  c.name = 'テスト会社'
  c.code = 'TEST001'
end

# テスト店舗
test_store = Store.find_or_create_by!(code: 'STORE001', company: test_company) do |s|
  s.name = 'テスト店舗'
end

puts "✓ テスト会社・店舗作成完了: #{test_company.name} / #{test_store.name}"

# 会社管理者
company_admin = User.find_or_create_by!(email: 'company_admin@example.com') do |u|
  u.password = 'password'
  u.password_confirmation = 'password'
  u.name = '会社管理者'
  u.role = :company_admin
  u.company = test_company
  u.store = test_store
  u.approved = true
end

puts "✓ 会社管理者作成完了: #{company_admin.email}"

# 店舗管理者
store_admin = User.find_or_create_by!(email: 'store_admin@example.com') do |u|
  u.password = 'password'
  u.password_confirmation = 'password'
  u.name = '店舗管理者'
  u.role = :store_admin
  u.company = test_company
  u.store = test_store
  u.approved = true
end

puts "✓ 店舗管理者作成完了: #{store_admin.email}"

puts "===== シード処理完了 ====="
