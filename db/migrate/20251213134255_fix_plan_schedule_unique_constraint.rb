class FixPlanScheduleUniqueConstraint < ActiveRecord::Migration[7.1]
  def up
    # 古い一意制約インデックスを削除
    remove_index :plan_schedules, name: "index_plan_schedules_on_plan_id_and_scheduled_date"
    
    # 新しい一意制約インデックスを追加（store_id と scheduled_date）
    add_index :plan_schedules, [:store_id, :scheduled_date], 
              unique: true, 
              name: "index_plan_schedules_on_store_id_and_scheduled_date"
  end

  def down
    # ロールバック用
    remove_index :plan_schedules, name: "index_plan_schedules_on_store_id_and_scheduled_date"
    add_index :plan_schedules, [:plan_id, :scheduled_date], 
              unique: true, 
              name: "index_plan_schedules_on_plan_id_and_scheduled_date"
  end
end
