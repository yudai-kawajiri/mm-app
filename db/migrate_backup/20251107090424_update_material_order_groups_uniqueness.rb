class UpdateMaterialOrderGroupsUniqueness < ActiveRecord::Migration[8.1]
  def change
    # 既存のユニークインデックス（user_id + name）を削除
    if index_exists?(:material_order_groups, [ :user_id, :name ], name: 'index_material_order_groups_on_user_id_and_name')
      remove_index :material_order_groups, name: 'index_material_order_groups_on_user_id_and_name'
    elsif index_exists?(:material_order_groups, [ :user_id, :name ])
      remove_index :material_order_groups, [ :user_id, :name ]
    end

    # 新しいユニークインデックス（name のみ）を追加
    unless index_exists?(:material_order_groups, :name, unique: true)
      add_index :material_order_groups, :name, unique: true
    end
  end
end
