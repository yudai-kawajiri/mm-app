class AddUserIdToPlanSchedules < ActiveRecord::Migration[7.0]
  def change
    # まずnull許可でカラム追加
    add_reference :plan_schedules, :user, null: true, foreign_key: true

    # 既存レコードにデフォルトユーザーを設定
    reversible do |dir|
      dir.up do
        # 最初のユーザーIDを取得して設定
        default_user_id = User.first&.id
        if default_user_id
          execute "UPDATE plan_schedules SET user_id = #{default_user_id} WHERE user_id IS NULL"
        end

        # null制約を追加
        change_column_null :plan_schedules, :user_id, false
      end
    end
  end
end
