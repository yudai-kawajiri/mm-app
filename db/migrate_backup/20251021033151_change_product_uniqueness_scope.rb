class ChangeProductUniquenessScope < ActiveRecord::Migration[8.0]
  def change
    # 1. name + category_id の組み合わせでユニークインデックスを追加
    add_index :products, [ :name, :category_id ], unique: true

    # 2. item_number + category_id の組み合わせでユニークインデックスを追加
    add_index :products, [ :item_number, :category_id ], unique: true
  end
end
