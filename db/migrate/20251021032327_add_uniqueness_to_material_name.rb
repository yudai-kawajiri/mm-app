class AddUniquenessToMaterialName < ActiveRecord::Migration[8.0]
  def change
    # name と category_id の組み合わせでユニークインデックスを追加
    add_index :materials, [ :name, :category_id ], unique: true
  end
end
