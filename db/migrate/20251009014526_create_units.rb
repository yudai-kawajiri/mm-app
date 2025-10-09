class CreateUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :units do |t|
      t.string :name, null: false # null: false を追加
      t.integer :category, default: 0, null: false # defaultとnull: falseを追加

      t.timestamps
    end
    # name が重複しないようにユニークインデックスを追加
    add_index :units, :name, unique: true
  end
end

