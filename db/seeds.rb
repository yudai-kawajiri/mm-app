# frozen_string_literal: true

# 管理者ユーザーを作成
admin = User.find_or_create_by!(email: 'admin@mm-app-manage.com') do |user|
  user.name = '管理者'
  user.password = 'password'
  user.password_confirmation = 'password'
  user.role = :admin
end

puts "  管理者アカウントを作成しました"
puts "   Email: #{admin.email}"
puts "   初期パスワード: password"
puts "   Role: #{admin.role}"
