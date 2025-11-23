class CreatePlanSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_schedules do |t|
      t.references :plan, null: false, foreign_key: true
      t.date :scheduled_date, null: false, comment: 'スケジュール実施日'
      t.decimal :actual_revenue, precision: 12, scale: 2, comment: '実績売上'
      t.integer :status, default: 0, null: false, comment: 'ステータス'
      t.text :description, comment: '概要'

      t.timestamps
    end

    # 同じ計画を同じ日に複数配置できないようにする
    add_index :plan_schedules, [ :plan_id, :scheduled_date ], unique: true

    # 日付検索の高速化
    add_index :plan_schedules, :scheduled_date
  end
end
