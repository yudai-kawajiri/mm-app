class RenameCompanySubdomainToSlug < ActiveRecord::Migration[8.1]
  def change
    rename_column :companies, :subdomain, :slug
  end
end
