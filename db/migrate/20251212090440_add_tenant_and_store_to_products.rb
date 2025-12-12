class AddTenantAndStoreToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :tenant, null: true, foreign_key: true
    add_reference :products, :store, null: true, foreign_key: true
    
    reversible do |dir|
      dir.up do
        # SQL で直接 tenant_id と store_id を取得
        tenant_id = execute("SELECT id FROM tenants ORDER BY id LIMIT 1").first&.fetch('id')
        store_id = execute("SELECT id FROM stores ORDER BY id LIMIT 1").first&.fetch('id')
        
        if tenant_id && store_id
          execute "UPDATE products SET tenant_id = #{tenant_id}, store_id = #{store_id} WHERE tenant_id IS NULL"
        end
      end
    end
    
    change_column_null :products, :tenant_id, false
  end
end
