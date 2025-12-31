class AddInvitationTokenToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :invitation_token, :string
    add_index :companies, :invitation_token, unique: true
  end
end
