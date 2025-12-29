class AddUserIdToApplicationRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :application_requests, :user_id, :bigint
  end
end
