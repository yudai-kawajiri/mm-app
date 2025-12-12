class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :tenants, :subdomain, unique: true
  end
end
