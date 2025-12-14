class CreateApplicationRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :application_requests do |t|
      t.string :company_name
      t.string :company_email
      t.string :company_phone
      t.string :admin_name
      t.string :admin_email
      t.integer :status
      t.string :invitation_token
      t.datetime :invitation_sent_at
      t.integer :tenant_id

      t.timestamps
    end
  end
end
