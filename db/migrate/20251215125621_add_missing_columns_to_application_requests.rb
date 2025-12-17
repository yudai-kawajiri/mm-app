class AddMissingColumnsToApplicationRequests < ActiveRecord::Migration[8.1]
  def change
    # user_id を追加（アカウント登録完了後にユーザーと紐付け）
    add_column :application_requests, :user_id, :integer, null: true
    add_index :application_requests, :user_id

    # invitation_token にユニーク制約を追加
    add_index :application_requests, :invitation_token, unique: true
  end
end
