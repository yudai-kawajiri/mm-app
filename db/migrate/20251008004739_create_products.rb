class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      # null: falseを設定
      t.string :name, null: false
      t.integer :price, null: false
      t.string :item_number, null: false
      t.string :image_url
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
