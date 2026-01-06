class AddDisplayOrderToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :display_order, :integer, default: 0, null: false
    add_index :categories, :display_order
  end
end
