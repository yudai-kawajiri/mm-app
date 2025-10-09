class AddUnitReferencesToMaterials < ActiveRecord::Migration[8.0]
  def change
    # 新しい外部キー（参照）を追加
    add_reference :materials, :basic_unit, null: false, foreign_key: { to_table: :units }
    add_reference :materials, :ordering_unit, null: false, foreign_key: { to_table: :units }

    # description カラムを再追加
    add_column :materials, :description, :text

    # 単位の名前を保存していた文字列型のカラム
    remove_column :materials, :unit_for_product, :string
    remove_column :materials, :unit_for_order, :string

  end
end
