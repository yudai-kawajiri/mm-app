class CreateMonthlyBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_budgets do |t|
      t.references :user, null: false, foreign_key: true
      t.date :budget_month, null: false, comment: '予算対象月（月初日を保存）'
      t.decimal :target_amount, precision: 12, scale: 2, null: false, comment: '目標金額'
      t.text :description, comment: '概要'

      t.timestamps
    end

    # 1ユーザー・1ヶ月に1つの予算のみ許可
    add_index :monthly_budgets, [ :user_id, :budget_month ], unique: true
  end
end
