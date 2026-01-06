class AddTemporaryPasswordToApplicationRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :application_requests, :temporary_password, :string
  end
end
