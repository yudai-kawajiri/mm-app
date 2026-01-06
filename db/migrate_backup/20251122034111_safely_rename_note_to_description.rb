# db/migrate/YYYYMMDDHHMMSS_safely_rename_note_to_description.rb
class SafelyRenameNoteToDescription < ActiveRecord::Migration[8.1]
  def up
    # 各テーブルのカラム存在確認後に変更
    if column_exists?(:plan_schedules, :note)
      rename_column :plan_schedules, :note, :description
      change_column_comment :plan_schedules, :description, from: "備考", to: "概要"
    end

    if column_exists?(:daily_targets, :note)
      rename_column :daily_targets, :note, :description
      change_column_comment :daily_targets, :description, from: "備考", to: "概要"
    end

    if column_exists?(:monthly_budgets, :note)
      rename_column :monthly_budgets, :note, :description
      change_column_comment :monthly_budgets, :description, from: "備考", to: "概要"
    end
  end

  def down
    rename_column :plan_schedules, :description, :note if column_exists?(:plan_schedules, :description)
    rename_column :daily_targets, :description, :note if column_exists?(:daily_targets, :description)
    rename_column :monthly_budgets, :description, :note if column_exists?(:monthly_budgets, :description)
  end
end
