class AddCompanyToProductMaterials < ActiveRecord::Migration[8.1]
  def change
    add_reference :product_materials, :company, null: true, foreign_key: true
    
    reversible do |dir|
      dir.up do
        company_id = execute("SELECT id FROM companies ORDER BY id LIMIT 1").first&.fetch('id')
        
        if company_id
          execute "UPDATE product_materials SET company_id = #{company_id} WHERE company_id IS NULL"
        end
      end
    end
    
    change_column_null :product_materials, :company_id, false
  end
end
