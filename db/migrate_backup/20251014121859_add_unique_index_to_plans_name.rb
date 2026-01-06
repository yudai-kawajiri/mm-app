class AddUniqueIndexToPlansName < ActiveRecord::Migration[8.0]
  def change
    add_index :plans, :name, unique: true
  end
end
