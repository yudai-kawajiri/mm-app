class FixUniqueConstraintsForStoreScope < ActiveRecord::Migration[7.2]
  def change
    # 1. MonthlyBudget: budget_month のユニーク制約を store_id を含む形に変更
    remove_index :monthly_budgets, name: "index_monthly_budgets_on_user_id_and_budget_month"
    add_index :monthly_budgets, [ :budget_month, :store_id ], unique: true, name: "index_monthly_budgets_on_budget_month_and_store_id"

    # 2. Product: name, reading, item_number のユニーク制約に store_id を追加
    remove_index :products, name: "index_products_on_name_and_category_id"
    remove_index :products, name: "index_products_on_reading_and_category_id"
    remove_index :products, name: "index_products_on_item_number_and_category_id"

    add_index :products, [ :name, :category_id, :store_id ], unique: true, name: "index_products_on_name_category_store"
    add_index :products, [ :reading, :category_id, :store_id ], unique: true, name: "index_products_on_reading_category_store"
    add_index :products, [ :item_number, :category_id, :store_id ], unique: true, name: "index_products_on_item_number_category_store"

    # 3. Material: name, reading のユニーク制約に store_id を追加
    remove_index :materials, name: "index_materials_on_name_and_category_id"
    remove_index :materials, name: "index_materials_on_reading_and_category_id"

    add_index :materials, [ :name, :category_id, :store_id ], unique: true, name: "index_materials_on_name_category_store"
    add_index :materials, [ :reading, :category_id, :store_id ], unique: true, name: "index_materials_on_reading_category_store"

    # 4. Plan: name, reading のユニーク制約に store_id を追加
    remove_index :plans, name: "index_plans_on_name_and_category_id"
    remove_index :plans, name: "index_plans_on_reading_and_category_id"

    add_index :plans, [ :name, :category_id, :store_id ], unique: true, name: "index_plans_on_name_category_store"
    add_index :plans, [ :reading, :category_id, :store_id ], unique: true, name: "index_plans_on_reading_category_store"

    # 5. Category: name, reading のユニーク制約に store_id を追加
    remove_index :categories, name: "index_categories_on_name_and_category_type"
    remove_index :categories, name: "index_categories_on_reading_and_category_type"

    add_index :categories, [ :name, :category_type, :store_id ], unique: true, name: "index_categories_on_name_type_store"
    add_index :categories, [ :reading, :category_type, :store_id ], unique: true, name: "index_categories_on_reading_type_store"

    # 6. Unit: name, reading のユニーク制約に store_id を追加
    remove_index :units, name: "index_units_on_name_and_category"
    remove_index :units, name: "index_units_on_reading_and_category"

    add_index :units, [ :name, :category, :store_id ], unique: true, name: "index_units_on_name_category_store"
    add_index :units, [ :reading, :category, :store_id ], unique: true, name: "index_units_on_reading_category_store"

    # 7. MaterialOrderGroup: name, reading のユニーク制約に store_id を追加
    remove_index :material_order_groups, name: "index_material_order_groups_on_name"
    remove_index :material_order_groups, name: "index_material_order_groups_on_reading"

    add_index :material_order_groups, [ :name, :store_id ], unique: true, name: "index_material_order_groups_on_name_store"
    add_index :material_order_groups, [ :reading, :store_id ], unique: true, name: "index_material_order_groups_on_reading_store"
  end
end
