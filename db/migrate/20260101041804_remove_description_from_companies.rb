class RemoveDescriptionFromCompanies < ActiveRecord::Migration[8.1]
  def change
    remove_column :companies, :description, :text
  end
end
