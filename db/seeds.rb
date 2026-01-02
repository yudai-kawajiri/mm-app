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
  c.email = 'admin@mm-app-manage.com'
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
  u.name = 'システム管理者'
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
portfolio_admin = User.find_or_create_by!(email: 'admin@mm-app-manage.com') do |u|
  u.password = 'Portfolio2026!'
  u.password_confirmation = 'Portfolio2026!'
  u.name = 'ポートフォリオ閲覧者（システム管理者）'
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
puts "   Password: Portfolio2026!"

# ====================
# 4. ポートフォリオ用テストデータ（魚屋の寿司）
# ====================
puts "\n=========================================="
puts "ポートフォリオ用テストデータを作成します..."
puts "=========================================="

# 会社の作成
uoya_company = Company.find_or_create_by!(slug: 'uoya-sushi') do |c|
  c.name = '魚屋の寿司株式会社'
  c.email = 'info@uoya-sushi.test'
  c.phone = '0312345678'
end
puts " 会社作成完了: #{uoya_company.name}"

# 店舗の作成
main_store = Store.find_or_create_by!(company: uoya_company, code: 'MAIN') do |s|
  s.name = '魚屋の寿司 本店'
  s.invitation_code = 'MAIN2026'
  s.active = true
end
puts " 店舗作成完了: #{main_store.name}"
puts "   招待コード: #{main_store.invitation_code}"

# 店舗管理者の作成
store_admin = User.find_or_create_by!(email: 'store-admin@uoya-sushi.test') do |u|
  u.password = 'Test2026!'
  u.password_confirmation = 'Test2026!'
  u.name = '店舗管理者'
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
puts "   Password: Test2026!"

# 一般スタッフの作成
staff_user = User.find_or_create_by!(email: 'staff@uoya-sushi.test') do |u|
  u.password = 'Test2026!'
  u.password_confirmation = 'Test2026!'
  u.name = '一般スタッフ'
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
puts "   Password: Test2026!"

puts "\n=========================================="
puts "シード処理完了"
puts "=========================================="
