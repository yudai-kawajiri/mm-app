# frozen_string_literal: true

# 本番環境で初回起動時に自動的にseedsを実行
if Rails.env.production?
  Rails.application.config.after_initialize do
    # フラグファイルのパス
    flag_file = Rails.root.join('tmp', 'seeds_executed.flag')

    # フラグファイルが存在しない場合のみseedsを実行
    unless File.exist?(flag_file)
      Rails.logger.info '==> Auto-seeding: Executing db/seed for the first time...'

      begin
        # seeds.rbを実行
        load Rails.root.join('db', 'seeds.rb')

        # フラグファイルを作成
        FileUtils.mkdir_p(Rails.root.join('tmp'))
        File.write(flag_file, Time.current.to_s)

        Rails.logger.info '==> Auto-seeding: Successfully completed!'
      rescue StandardError => e
        Rails.logger.error "==> Auto-seeding failed: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    else
      Rails.logger.info '==> Auto-seeding: Already executed (skipping)'
    end
  end
end
