# lib/tasks/system_logs.rake

namespace :system_logs do
  desc 'システムログの自動削除（指定期間より古いログを削除）'
  task auto_delete: :environment do
    # 環境変数から保持期間を取得（デフォルト: 365日）
    retention_days = ENV.fetch('SYSTEM_LOG_RETENTION_DAYS', 365).to_i
    cutoff_date = retention_days.days.ago

    # 削除対象のログ件数をカウント
    target_count = PaperTrail::Version.where('created_at < ?', cutoff_date).count

    if target_count.zero?
      puts I18n.t('system_logs.auto_delete.no_logs_to_delete', retention_days: retention_days)
      next
    end

    # 削除実行
    deleted_count = PaperTrail::Version.where('created_at < ?', cutoff_date).delete_all

    # 結果をログ出力
    puts I18n.t('system_logs.auto_delete.success',
                deleted_count: deleted_count,
                retention_days: retention_days,
                cutoff_date: I18n.l(cutoff_date, format: :long))

    # Railsログにも記録
    Rails.logger.info "[SystemLogs] #{deleted_count}件のログを削除しました（#{retention_days}日より古いログ）"
  end
end
