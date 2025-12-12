class AddTenantToVersions < ActiveRecord::Migration[8.1]
  def change
    add_reference :versions, :tenant, null: false, foreign_key: true
  end
end
