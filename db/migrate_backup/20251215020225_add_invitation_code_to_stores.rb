class AddInvitationCodeToStores < ActiveRecord::Migration[8.1]
  def change
    add_column :stores, :invitation_code, :string
  end
end
