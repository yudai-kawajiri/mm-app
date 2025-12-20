class AddCompanyAndStoreToUnits < ActiveRecord::Migration[8.1]
  def change
    add_reference :units, :company, null: true, foreign_key: true
    add_reference :units, :store, null: true, foreign_key: true
    
    reversible do |dir|
      dir.up do
        tenant_id = execute("SELECT id FROM companies ORDER BY id LIMIT 1").first&.fetch('id')
        store_id = execute("SELECT id FROM stores ORDER BY id LIMIT 1").first&.fetch('id')
        
        if tenant_id && store_id
          execute "UPDATE units SET tenant_id = #{tenant_id}, store_id = #{store_id} WHERE tenant_id IS NULL"
        end
      end
    end
    
    change_column_null :units, :company_id, false
  end
end
