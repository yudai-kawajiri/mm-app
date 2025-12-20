class AddCompanyToProductMaterials < ActiveRecord::Migration[8.1]
  def change
    add_reference :product_materials, :company, null: true, foreign_key: true
    
    reversible do |dir|
      dir.up do
        tenant_id = execute("SELECT id FROM tenants ORDER BY id LIMIT 1").first&.fetch('id')
        
        if tenant_id
          execute "UPDATE product_materials SET tenant_id = #{tenant_id} WHERE tenant_id IS NULL"
        end
      end
    end
    
    change_column_null :product_materials, :company_id, false
  end
end
