# frozen_string_literal: true

# 本番環境で環境変数 RUN_SEEDS=true が設定されている場合のみ seeds を実行
if Rails.env.production? && ENV['RUN_SEEDS'] == 'true'
  Rails.application.config.after_initialize do
    Rails.logger.info '==> Running seeds.rb (triggered by RUN_SEEDS env var)...'
    begin
      load Rails.root.join('db', 'seeds.rb')
      Rails.logger.info '==> Seeds execution completed!'
    rescue StandardError => e
      Rails.logger.error "==> Seeds failed: #{e.message}"
    end
  end
end
