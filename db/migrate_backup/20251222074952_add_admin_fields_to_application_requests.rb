class AddAdminFieldsToApplicationRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :application_requests, :admin_name, :string
    add_column :application_requests, :admin_email, :string
  end
end
