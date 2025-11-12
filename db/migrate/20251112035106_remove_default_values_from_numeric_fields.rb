class RemoveDefaultValuesFromNumericFields < ActiveRecord::Migration[8.1]
  def up
    # materials テーブル - 原材料登録画面で使用
    change_column_default :materials, :default_unit_weight, from: 0.0, to: nil
    change_column_default :materials, :unit_weight_for_order, from: 0.0, to: nil
    change_column_default :materials, :pieces_per_order_unit, from: 0, to: nil

    # product_materials テーブル - 商品原材料で使用
    change_column_default :product_materials, :quantity, from: 0.0, to: nil
    change_column_default :product_materials, :unit_weight, from: 0.0, to: nil

    # plan_products テーブル - 製造計画で使用
    change_column_default :plan_products, :production_count, from: 0.0, to: nil
  end

  def down
    # ロールバック用
    change_column_default :materials, :default_unit_weight, from: nil, to: 0.0
    change_column_default :materials, :unit_weight_for_order, from: nil, to: 0.0
    change_column_default :materials, :pieces_per_order_unit, from: nil, to: 0

    change_column_default :product_materials, :quantity, from: nil, to: 0.0
    change_column_default :product_materials, :unit_weight, from: nil, to: 0.0

    change_column_default :plan_products, :production_count, from: nil, to: 0.0
  end
end
