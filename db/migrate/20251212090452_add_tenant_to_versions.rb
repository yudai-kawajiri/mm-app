class AddTenantToVersions < ActiveRecord::Migration[8.1]
  def change
    add_reference :versions, :tenant, null: true, foreign_key: true
    
    reversible do |dir|
      dir.up do
        tenant_id = execute("SELECT id FROM tenants ORDER BY id LIMIT 1").first&.fetch('id')
        
        if tenant_id
          execute "UPDATE versions SET tenant_id = #{tenant_id} WHERE tenant_id IS NULL"
        end
      end
    end
  end
end
