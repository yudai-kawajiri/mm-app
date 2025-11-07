class ForceConvertProductionUnitToReference < ActiveRecord::Migration[8.1]
  def up
    # 既存のインデックスを削除
    remove_index :materials, :production_unit if index_exists?(:materials, :production_unit)

    # 既存のproduction_unitカラム（string型）を削除
    remove_column :materials, :production_unit if column_exists?(:materials, :production_unit)

    # 新しくproduction_unit_idカラム（外部キー）を追加
    add_reference :materials, :production_unit, foreign_key: { to_table: :units }, index: true
  end

  def down
    # ロールバック時の処理
    remove_reference :materials, :production_unit, foreign_key: { to_table: :units }, index: true
    add_column :materials, :production_unit, :string
    add_index :materials, :production_unit
  end
end