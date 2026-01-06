class RemoveContactFieldsFromApplicationRequests < ActiveRecord::Migration[8.1]
  def change
    remove_column :application_requests, :contact_name, :string
    remove_column :application_requests, :contact_email, :string
  end
end
