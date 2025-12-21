class AddCompanyToVersions < ActiveRecord::Migration[8.1]
  def change
    add_reference :versions, :company, null: true, foreign_key: true

    reversible do |dir|
      dir.up do
        company_id = execute("SELECT id FROM companies ORDER BY id LIMIT 1").first&.fetch('id')

        if company_id
          execute "UPDATE versions SET company_id = #{company_id} WHERE company_id IS NULL"
        end
      end
    end
  end
end
