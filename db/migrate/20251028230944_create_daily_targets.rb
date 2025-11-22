class CreateDailyTargets < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_targets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :monthly_budget, null: false, foreign_key: true
      t.date :target_date, null: false
      t.decimal :target_amount, precision: 12, scale: 2, null: false
      t.text :description

      t.timestamps
    end

    add_index :daily_targets, [ :monthly_budget_id, :target_date ], unique: true, name: "index_daily_targets_on_budget_and_date"
    add_index :daily_targets, :target_date
  end
end
