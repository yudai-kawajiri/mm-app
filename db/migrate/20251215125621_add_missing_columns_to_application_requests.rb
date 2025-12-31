class AddMissingColumnsToApplicationRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :application_requests, :company_name, :string
    add_column :application_requests, :company_phone, :string
    add_column :application_requests, :company_address, :string
    add_column :application_requests, :status, :integer, default: 0, null: false
    add_column :application_requests, :approved_by_id, :bigint
    add_column :application_requests, :approved_at, :datetime
    add_column :application_requests, :rejection_reason, :text
    
    add_index :application_requests, :status
    add_index :application_requests, :approved_by_id
  end
end
