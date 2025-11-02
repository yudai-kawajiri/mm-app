class AddDisplayOrderToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :display_order, :integer

    # 既存データにデフォルト値を設定（ID順）
    reversible do |dir|
      dir.up do
        Product.order(:id).each_with_index do |product, index|
          product.update_column(:display_order, index + 1)
        end
      end
    end
  end
end
