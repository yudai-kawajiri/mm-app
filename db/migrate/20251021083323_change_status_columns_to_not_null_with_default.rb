class ChangeStatusColumnsToNotNullWithDefault < ActiveRecord::Migration[8.0]
  def up
    # 1. Product テーブルの修正
    # 既存の NULL 値を持つレコードを 'draft' (0) に更新 (データ破損防止)
    Product.where(status: nil).update_all(status: 0)

    change_column_null :products, :status, false, 0
    change_column_default :products, :status, from: nil, to: 0

    # 2. Plan テーブルの修正
    Plan.where(status: nil).update_all(status: 0)

    change_column_null :plans, :status, false, 0
    change_column_default :plans, :status, from: nil, to: 0
  end

  def down
    # ロールバック時は NOT NULL 制約とデフォルト値を削除
    change_column_null :products, :status, true
    change_column_default :products, :status, from: 0, to: nil

    change_column_null :plans, :status, true
    change_column_default :plans, :status, from: 0, to: nil
  end
end