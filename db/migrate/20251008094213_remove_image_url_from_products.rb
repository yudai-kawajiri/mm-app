class RemoveImageUrlFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :image_url, :string
  end
end
