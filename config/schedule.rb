# config/schedule.rb

# Ruby実行環境のパスを設定
env :PATH, ENV["PATH"]

# Railsアプリケーションのログ出力先を設定
set :output, "#{path}/log/cron.log"

# cronのタイムゾーンを日本時間に設定
set :chronic_options, time_zone: "Tokyo"

# 毎日午前3時にシステムログの自動削除を実行
every 1.day, at: "3:00 am" do
  rake "system_logs:auto_delete"
end
