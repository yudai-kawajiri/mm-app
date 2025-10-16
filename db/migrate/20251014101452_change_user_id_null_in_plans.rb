class ChangeUserIdNullInPlans < ActiveRecord::Migration[7.1]
  def change
    # null: false から null: true に変更
    change_column_null :plans, :user_id, true
  end
end
