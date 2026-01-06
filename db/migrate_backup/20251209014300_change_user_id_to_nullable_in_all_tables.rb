# frozen_string_literal: true

# 全テーブルのuser_idをnullable化
# 理由: システムは全認証ユーザーでデータを共有するため、user_idは履歴記録用のみ
class ChangeUserIdToNullableInAllTables < ActiveRecord::Migration[8.1]
  def change
    # user_idをnullable化（NOT NULL制約を削除）
    change_column_null :categories, :user_id, true
    change_column_null :daily_targets, :user_id, true
    change_column_null :material_order_groups, :user_id, true
    change_column_null :materials, :user_id, true
    change_column_null :monthly_budgets, :user_id, true
    change_column_null :plan_schedules, :user_id, true
    change_column_null :plans, :user_id, true
    change_column_null :products, :user_id, true
    change_column_null :units, :user_id, true
  end
end
