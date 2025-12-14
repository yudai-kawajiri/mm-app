class AddInvitationTokenToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :invitation_token, :string
    add_column :tenants, :invitation_sent_at, :datetime
    add_column :tenants, :invitation_accepted_at, :datetime
    add_column :tenants, :company_email, :string
    add_column :tenants, :company_phone, :string
  end
end
