# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_21_044344) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "category_type", default: 0, null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "category_type"], name: "index_categories_on_name_and_category_type", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "materials", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "unit_weight_for_product", precision: 10, scale: 3, null: false
    t.decimal "unit_weight_for_order", precision: 10, scale: 3, null: false
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "unit_for_order_id", null: false
    t.text "description"
    t.bigint "unit_for_product_id", null: false
    t.index ["category_id"], name: "index_materials_on_category_id"
    t.index ["name", "category_id"], name: "index_materials_on_name_and_category_id", unique: true
    t.index ["unit_for_order_id"], name: "index_materials_on_unit_for_order_id"
    t.index ["unit_for_product_id"], name: "index_materials_on_unit_for_product_id"
    t.index ["user_id"], name: "index_materials_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.index ["category_id"], name: "index_plans_on_category_id"
    t.index ["name", "category_id"], name: "index_plans_on_name_and_category_id", unique: true
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "product_materials", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "material_id", null: false
    t.decimal "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "unit_id", null: false
    t.index ["material_id"], name: "index_product_materials_on_material_id"
    t.index ["product_id"], name: "index_product_materials_on_product_id"
    t.index ["unit_id"], name: "index_product_materials_on_unit_id"
  end

  create_table "product_plans", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "product_id", null: false
    t.integer "production_count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id", "product_id"], name: "index_product_plans_on_plan_id_and_product_id", unique: true
    t.index ["plan_id"], name: "index_product_plans_on_plan_id"
    t.index ["product_id"], name: "index_product_plans_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.integer "price", null: false
    t.string "item_number", null: false
    t.integer "status"
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["item_number", "category_id"], name: "index_products_on_item_number_and_category_id", unique: true
    t.index ["name", "category_id"], name: "index_products_on_name_and_category_id", unique: true
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "name", null: false
    t.integer "category", default: 0, null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "category"], name: "index_units_on_name_and_category", unique: true
    t.index ["user_id"], name: "index_units_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "categories", "users"
  add_foreign_key "materials", "categories"
  add_foreign_key "materials", "units", column: "unit_for_order_id"
  add_foreign_key "materials", "units", column: "unit_for_product_id"
  add_foreign_key "materials", "users"
  add_foreign_key "plans", "categories"
  add_foreign_key "plans", "users"
  add_foreign_key "product_materials", "materials"
  add_foreign_key "product_materials", "products"
  add_foreign_key "product_materials", "units"
  add_foreign_key "product_plans", "plans"
  add_foreign_key "product_plans", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "users"
  add_foreign_key "units", "users"
end
