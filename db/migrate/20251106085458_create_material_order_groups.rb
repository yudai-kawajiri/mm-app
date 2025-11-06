class CreateMaterialOrderGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :material_order_groups do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :material_order_groups, [:user_id, :name], unique: true
  end
end
