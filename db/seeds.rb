puts "データベースのシード処理を開始"

admin_company = Company.find_or_create_by!(slug: 'admin') do |c|
  c.name = 'システム管理'
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

# 既存ユーザーの role を強制的に更新
admin_user.update!(role: :super_admin, approved: true, company: admin_company)

puts "システム管理者作成完了: #{admin_user.email}"
puts "Role: #{admin_user.role}"
puts "Super Admin?: #{admin_user.super_admin?}"

puts "シード処理完了"
