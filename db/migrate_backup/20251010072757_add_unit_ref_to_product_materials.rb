class AddUnitRefToProductMaterials < ActiveRecord::Migration[8.0]
  def change
    # unit_id を追加し、外部キーとして設定
    add_reference :product_materials, :unit, null: false, foreign_key: true
  end
end
