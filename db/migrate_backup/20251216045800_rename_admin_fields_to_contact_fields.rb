class RenameAdminFieldsToContactFields < ActiveRecord::Migration[8.1]
  def change
    rename_column :application_requests, :admin_name, :contact_name
    rename_column :application_requests, :admin_email, :contact_email
  end
end
