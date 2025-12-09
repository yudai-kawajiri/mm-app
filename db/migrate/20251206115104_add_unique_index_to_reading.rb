class AddUniqueIndexToReading < ActiveRecord::Migration[7.0]
  def change
    # 既存の reading インデックス（ユニークなし）を先に削除
    remove_index :products, name: 'index_products_on_reading' if index_exists?(:products, :reading, name: 'index_products_on_reading')
    remove_index :materials, name: 'index_materials_on_reading' if index_exists?(:materials, :reading, name: 'index_materials_on_reading')
    remove_index :categories, name: 'index_categories_on_reading' if index_exists?(:categories, :reading, name: 'index_categories_on_reading')
    remove_index :units, name: 'index_units_on_reading' if index_exists?(:units, :reading, name: 'index_units_on_reading')
    remove_index :material_order_groups, name: 'index_material_order_groups_on_reading' if index_exists?(:material_order_groups, :reading, name: 'index_material_order_groups_on_reading')
    remove_index :plans, name: 'index_plans_on_reading' if index_exists?(:plans, :reading, name: 'index_plans_on_reading')

    # products: reading + category_id で一意
    add_index :products, [ :reading, :category_id ], unique: true, name: 'index_products_on_reading_and_category_id'

    # materials: reading + category_id で一意
    add_index :materials, [ :reading, :category_id ], unique: true, name: 'index_materials_on_reading_and_category_id'

    # categories: reading + category_type で一意
    add_index :categories, [ :reading, :category_type ], unique: true, name: 'index_categories_on_reading_and_category_type'

    # units: reading + category で一意
    add_index :units, [ :reading, :category ], unique: true, name: 'index_units_on_reading_and_category'

    # material_order_groups: reading はグローバルで一意
    add_index :material_order_groups, :reading, unique: true, name: 'index_material_order_groups_on_reading'

    # plans: reading + category_id で一意
    add_index :plans, [ :reading, :category_id ], unique: true, name: 'index_plans_on_reading_and_category_id'
  end
end
