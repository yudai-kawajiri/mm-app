# frozen_string_literal: true

class AddDefaultToDisplayOrder < ActiveRecord::Migration[8.1]
  def up
    # 既存のnilレコードにデフォルト値を設定
    Resources::Material.where(display_order: nil).update_all(display_order: 999999)
    Resources::Product.where(display_order: nil).update_all(display_order: 999999)

    # カラムにデフォルト値を設定
    change_column_default :materials, :display_order, from: nil, to: 999999
    change_column_default :products, :display_order, from: nil, to: 999999
  end

  def down
    # ロールバック時はデフォルト値を削除
    change_column_default :materials, :display_order, from: 999999, to: nil
    change_column_default :products, :display_order, from: 999999, to: nil
  end
end
