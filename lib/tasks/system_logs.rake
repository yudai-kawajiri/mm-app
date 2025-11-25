# lib/tasks/system_logs.rake

namespace :system_logs do
  desc "システムログの自動削除（指定期間より古いログを削除）"
  task auto_delete: :environment do
    # 環境変数から保持期間を取得（デフォルト: 365日）
    retention_days = ENV.fetch("SYSTEM_LOG_RETENTION_DAYS", 365).to_i
    cutoff_date = retention_days.days.ago

    # 削除対象のログ件数をカウント
    count_sql = "SELECT COUNT(*) FROM versions WHERE created_at < ?"
    target_count = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([ count_sql, cutoff_date ])
    ).first["count"].to_i

    if target_count.zero?
      puts I18n.t("admin.system_logs.auto_delete.no_logs_to_delete", retention_days: retention_days)
      next
    end

    # 削除実行
    delete_sql = "DELETE FROM versions WHERE created_at < ?"
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql_array([ delete_sql, cutoff_date ])
    )

    # 結果をログ出力
    puts I18n.t("admin.system_logs.auto_delete.success",
                deleted_count: target_count,
                retention_days: retention_days,
                cutoff_date: I18n.l(cutoff_date, format: :long))

    # Railsログにも記録
    Rails.logger.info "[SystemLogs] #{target_count}件のログを削除しました（#{retention_days}日より古いログ）"
  end
end
