class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false         # null: false を追加
      t.integer :price, null: false        # null: false を追加
      t.string :item_number, null: false  #  null: false を追加
      t.integer :status

      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end