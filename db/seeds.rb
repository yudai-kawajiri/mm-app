puts "データベースのシード処理を開始"

admin_company = Company.find_or_create_by!(slug: 'admin') do |c|
  c.name = 'システム管理'
  c.code = 'admin'
end

puts "会社作成完了: #{admin_company.name}"

admin_user = User.find_or_create_by!(email: 'mmapp@outlook.jp') do |u|
  u.password = 'password'
  u.password_confirmation = 'password'
  u.name = 'システム管理者'
  u.role = :super_admin
  u.company = admin_company
  u.approved = true
end

puts "システム管理者作成完了: #{admin_user.email}"

puts "シード処理完了"
