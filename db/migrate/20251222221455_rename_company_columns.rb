class RenameCompanyColumns < ActiveRecord::Migration[8.1]
  def change
    rename_column :companies, :company_email, :email
    rename_column :companies, :company_phone, :phone
  end
end
