class AddOrderConversionToMaterials < ActiveRecord::Migration[8.1]
  def change
    # デフォルトの1単位重量（例: 1枚=12g）
    add_column :materials, :default_unit_weight, :decimal, precision: 10, scale: 3, default: 0, comment: "デフォルトの1単位あたり重量（g）"

    # 発注単位あたりの個数（例: 1箱=50枚）
    add_column :materials, :pieces_per_order_unit, :integer, comment: "1発注単位あたりの個数（トレイなど）"
  end
end
