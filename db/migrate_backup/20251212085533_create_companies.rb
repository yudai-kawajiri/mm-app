class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :code, null: false
      t.string :phone
      t.string :address
      t.text :description

      t.timestamps
    end

    add_index :companies, :slug, unique: true
    add_index :companies, :code, unique: true
  end
end
