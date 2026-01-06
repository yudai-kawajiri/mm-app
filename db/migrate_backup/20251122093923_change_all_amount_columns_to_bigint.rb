class ChangeAllAmountColumnsToBigint < ActiveRecord::Migration[8.1]
  def up
    # daily_targets.target_amount を bigint に変更
    change_column :daily_targets, :target_amount, :bigint,
                  using: 'target_amount::bigint',
                  null: false,
                  comment: '目標金額'

    # monthly_budgets.target_amount を bigint に変更
    change_column :monthly_budgets, :target_amount, :bigint,
                  using: 'target_amount::bigint',
                  null: false,
                  comment: '目標金額'
  end

  def down
    # ロールバック用
    change_column :daily_targets, :target_amount, :decimal,
                  precision: 12, scale: 2,
                  null: false,
                  comment: '目標金額'

    change_column :monthly_budgets, :target_amount, :decimal,
                  precision: 12, scale: 2,
                  null: false,
                  comment: '目標金額'
  end
end
