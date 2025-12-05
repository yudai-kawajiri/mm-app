# frozen_string_literal: true

# 本番環境で初回起動時にのみseeds.rbを自動実行
if Rails.env.production?
  Rails.application.config.after_initialize do
    unless File.exist?(Rails.root.join('tmp', 'seeds_executed.flag'))
      Rails.logger.info '==> Auto-seeding: Executing db/seed for the first time...'
      begin
        load Rails.root.join('db', 'seeds.rb')
        FileUtils.touch(Rails.root.join('tmp', 'seeds_executed.flag'))
        Rails.logger.info '==> Auto-seeding: Successfully completed!'
      rescue StandardError => e
        Rails.logger.error "==> Auto-seeding failed: #{e.message}"
      end
    end
  end
end
