class CreateStores < ActiveRecord::Migration[8.1]
  def change
    create_table :stores do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code
      t.text :address
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :stores, [:tenant_id, :code], unique: true
  end
end
