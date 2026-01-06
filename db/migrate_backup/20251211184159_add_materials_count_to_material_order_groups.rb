# frozen_string_literal: true

class AddMaterialsCountToMaterialOrderGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :material_order_groups, :materials_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE material_order_groups
          SET materials_count = (
            SELECT COUNT(*)
            FROM materials
            WHERE materials.order_group_id = material_order_groups.id
          )
        SQL
      end
    end
  end
end
