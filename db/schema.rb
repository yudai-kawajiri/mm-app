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

ActiveRecord::Schema[8.1].define(version: 2026_01_09_045003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.uuid "store_id"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["company_id"], name: "index_active_storage_attachments_on_company_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    t.index ["store_id"], name: "index_active_storage_attachments_on_store_id"
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "approved_at", comment: "承認日時"
    t.uuid "approved_by_id", comment: "承認者のUser ID"
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.text "message", comment: "リクエストメッセージ"
    t.text "rejection_reason", comment: "却下理由"
    t.integer "request_type", default: 0, null: false, comment: "0: store_admin_request"
    t.integer "status", default: 0, null: false, comment: "0: pending, 1: approved, 2: rejected"
    t.uuid "store_id", comment: "対象店舗（店舗管理者リクエストの場合）"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false, comment: "リクエスト送信者"
    t.index ["approved_by_id"], name: "index_admin_requests_on_approved_by_id"
    t.index ["company_id", "status"], name: "index_admin_requests_on_company_id_and_status"
    t.index ["company_id"], name: "index_admin_requests_on_company_id"
    t.index ["store_id"], name: "index_admin_requests_on_store_id"
    t.index ["user_id", "status"], name: "index_admin_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_admin_requests_on_user_id"
  end

  create_table "application_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "admin_email"
    t.string "admin_name"
    t.string "company_email"
    t.uuid "company_id"
    t.string "company_name"
    t.string "company_phone"
    t.datetime "created_at", null: false
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "status"
    t.string "temporary_password"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category_type"
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order", default: 0, null: false
    t.string "name", null: false
    t.string "reading"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["company_id"], name: "index_categories_on_company_id"
    t.index ["display_order"], name: "index_categories_on_display_order"
    t.index ["name", "category_type", "store_id"], name: "index_categories_on_name_type_store", unique: true
    t.index ["reading", "category_type", "store_id"], name: "index_categories_on_reading_type_store", unique: true
    t.index ["store_id"], name: "index_categories_on_store_id"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "invitation_token"
    t.string "name", null: false
    t.string "phone"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["invitation_token"], name: "index_companies_on_invitation_token", unique: true
    t.index ["phone"], name: "index_companies_on_phone", unique: true
    t.index ["slug"], name: "index_companies_on_slug", unique: true
  end

  create_table "daily_targets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.uuid "monthly_budget_id", null: false
    t.uuid "store_id"
    t.bigint "target_amount", null: false, comment: "目標金額"
    t.date "target_date", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["company_id"], name: "index_daily_targets_on_company_id"
    t.index ["monthly_budget_id", "target_date"], name: "index_daily_targets_on_budget_and_date", unique: true
    t.index ["monthly_budget_id"], name: "index_daily_targets_on_monthly_budget_id"
    t.index ["store_id"], name: "index_daily_targets_on_store_id"
    t.index ["target_date"], name: "index_daily_targets_on_target_date"
    t.index ["user_id"], name: "index_daily_targets_on_user_id"
  end

  create_table "material_order_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.integer "materials_count", default: 0, null: false
    t.string "name", null: false
    t.string "reading"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["company_id"], name: "index_material_order_groups_on_company_id"
    t.index ["name", "store_id"], name: "index_material_order_groups_on_name_store", unique: true
    t.index ["reading", "store_id"], name: "index_material_order_groups_on_reading_store", unique: true
    t.index ["store_id"], name: "index_material_order_groups_on_store_id"
    t.index ["user_id"], name: "index_material_order_groups_on_user_id"
  end

  create_table "materials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.decimal "default_unit_weight", precision: 10, scale: 3, comment: "デフォルトの1単位あたり重量（g）"
    t.text "description"
    t.integer "display_order"
    t.string "measurement_type", default: "weight", null: false
    t.string "name", null: false
    t.uuid "order_group_id"
    t.string "order_group_name"
    t.integer "pieces_per_order_unit", comment: "1発注単位あたりの個数（トレイなど）"
    t.uuid "production_unit_id"
    t.string "reading"
    t.uuid "store_id"
    t.uuid "unit_for_order_id", null: false
    t.uuid "unit_for_product_id", null: false
    t.decimal "unit_weight_for_order", precision: 10, scale: 3
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["category_id"], name: "index_materials_on_category_id"
    t.index ["company_id"], name: "index_materials_on_company_id"
    t.index ["measurement_type"], name: "index_materials_on_measurement_type"
    t.index ["name", "category_id", "store_id"], name: "index_materials_on_name_category_store", unique: true
    t.index ["order_group_id"], name: "index_materials_on_order_group_id"
    t.index ["production_unit_id"], name: "index_materials_on_production_unit_id"
    t.index ["reading", "category_id", "store_id"], name: "index_materials_on_reading_category_store", unique: true
    t.index ["store_id"], name: "index_materials_on_store_id"
    t.index ["unit_for_order_id"], name: "index_materials_on_unit_for_order_id"
    t.index ["unit_for_product_id"], name: "index_materials_on_unit_for_product_id"
    t.index ["user_id"], name: "index_materials_on_user_id"
  end

  create_table "monthly_budgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "budget_month", null: false, comment: "予算対象月（月初日を保存）"
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.text "description", comment: "説明"
    t.decimal "forecast_discount_rate", precision: 5, scale: 2, default: "0.0", null: false, comment: "予測見切り率（%）"
    t.uuid "store_id"
    t.bigint "target_amount", null: false, comment: "目標金額"
    t.decimal "target_discount_rate", precision: 5, scale: 2, default: "0.0", null: false, comment: "目標見切り率（%）"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["budget_month", "store_id"], name: "index_monthly_budgets_on_budget_month_and_store_id", unique: true
    t.index ["company_id"], name: "index_monthly_budgets_on_company_id"
    t.index ["store_id"], name: "index_monthly_budgets_on_store_id"
    t.index ["user_id"], name: "index_monthly_budgets_on_user_id"
  end

  create_table "plan_products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.uuid "plan_id", null: false
    t.uuid "product_id", null: false
    t.integer "production_count", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_plan_products_on_company_id"
    t.index ["plan_id", "product_id"], name: "index_plan_products_on_plan_id_and_product_id", unique: true
    t.index ["plan_id"], name: "index_plan_products_on_plan_id"
    t.index ["product_id"], name: "index_plan_products_on_product_id"
  end

  create_table "plan_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "actual_revenue", comment: "実績売上"
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.text "description", comment: "説明"
    t.uuid "plan_id"
    t.jsonb "plan_products_snapshot", default: {}, null: false, comment: "計画商品のスナップショット（日別調整用）"
    t.date "scheduled_date", null: false, comment: "スケジュール実施日"
    t.integer "status", default: 0, null: false, comment: "ステータス"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["company_id"], name: "index_plan_schedules_on_company_id"
    t.index ["plan_id"], name: "index_plan_schedules_on_plan_id"
    t.index ["plan_products_snapshot"], name: "index_plan_schedules_on_plan_products_snapshot", using: :gin
    t.index ["scheduled_date"], name: "index_plan_schedules_on_scheduled_date"
    t.index ["store_id", "scheduled_date"], name: "index_plan_schedules_on_store_id_and_scheduled_date", unique: true
    t.index ["store_id"], name: "index_plan_schedules_on_store_id"
    t.index ["user_id"], name: "index_plan_schedules_on_user_id"
  end

  create_table "plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "reading"
    t.integer "status"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["category_id"], name: "index_plans_on_category_id"
    t.index ["company_id"], name: "index_plans_on_company_id"
    t.index ["name", "category_id", "store_id"], name: "index_plans_on_name_category_store", unique: true
    t.index ["reading", "category_id", "store_id"], name: "index_plans_on_reading_category_store", unique: true
    t.index ["store_id"], name: "index_plans_on_store_id"
    t.index ["user_id"], name: "index_plans_on_user_id"
  end

  create_table "product_materials", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.uuid "material_id", null: false
    t.uuid "product_id", null: false
    t.decimal "quantity", precision: 10, scale: 3, null: false
    t.uuid "unit_id", null: false
    t.decimal "unit_weight", precision: 10, scale: 3, null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_product_materials_on_company_id"
    t.index ["material_id"], name: "index_product_materials_on_material_id"
    t.index ["product_id", "material_id"], name: "index_product_materials_on_product_id_and_material_id", unique: true
    t.index ["product_id"], name: "index_product_materials_on_product_id"
    t.index ["unit_id"], name: "index_product_materials_on_unit_id"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order"
    t.string "item_number", null: false
    t.string "name", null: false
    t.integer "price", null: false
    t.string "reading"
    t.integer "status"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["item_number", "category_id", "store_id"], name: "index_products_on_item_number_category_store", unique: true
    t.index ["name", "category_id", "store_id"], name: "index_products_on_name_category_store", unique: true
    t.index ["reading", "category_id", "store_id"], name: "index_products_on_reading_category_store", unique: true
    t.index ["store_id"], name: "index_products_on_store_id"
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "stores", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code"
    t.uuid "company_id", null: false
    t.datetime "created_at", null: false
    t.string "invitation_code"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "code"], name: "index_stores_on_company_id_and_code", unique: true
    t.index ["company_id"], name: "index_stores_on_company_id"
  end

  create_table "units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category"
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "reading"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["company_id"], name: "index_units_on_company_id"
    t.index ["name", "category", "store_id"], name: "index_units_on_name_category_store", unique: true
    t.index ["reading", "category", "store_id"], name: "index_units_on_reading_category_store", unique: true
    t.index ["store_id"], name: "index_units_on_store_id"
    t.index ["user_id"], name: "index_units_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "approved", default: false, null: false
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.uuid "store_id"
    t.datetime "updated_at", null: false
    t.index ["approved"], name: "index_users_on_approved"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["store_id"], name: "index_users_on_store_id"
  end

  create_table "versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at"
    t.string "event", null: false
    t.uuid "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.uuid "store_id"
    t.string "whodunnit"
    t.index ["company_id"], name: "index_versions_on_company_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["store_id"], name: "index_versions_on_store_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_attachments", "companies"
  add_foreign_key "active_storage_attachments", "stores"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_requests", "companies", on_delete: :cascade
  add_foreign_key "admin_requests", "stores"
  add_foreign_key "admin_requests", "users", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "admin_requests", "users", on_delete: :cascade
  add_foreign_key "categories", "companies", on_delete: :cascade
  add_foreign_key "categories", "stores", on_delete: :cascade
  add_foreign_key "categories", "users", on_delete: :cascade
  add_foreign_key "daily_targets", "companies"
  add_foreign_key "daily_targets", "monthly_budgets", on_delete: :cascade
  add_foreign_key "daily_targets", "stores", on_delete: :cascade
  add_foreign_key "daily_targets", "users"
  add_foreign_key "material_order_groups", "companies", on_delete: :cascade
  add_foreign_key "material_order_groups", "stores", on_delete: :cascade
  add_foreign_key "material_order_groups", "users"
  add_foreign_key "materials", "categories", on_delete: :cascade
  add_foreign_key "materials", "companies", on_delete: :cascade
  add_foreign_key "materials", "material_order_groups", column: "order_group_id", on_delete: :nullify
  add_foreign_key "materials", "stores", on_delete: :cascade
  add_foreign_key "materials", "units", column: "production_unit_id"
  add_foreign_key "materials", "units", column: "unit_for_order_id"
  add_foreign_key "materials", "units", column: "unit_for_product_id"
  add_foreign_key "materials", "users"
  add_foreign_key "monthly_budgets", "companies", on_delete: :cascade
  add_foreign_key "monthly_budgets", "stores", on_delete: :cascade
  add_foreign_key "monthly_budgets", "users"
  add_foreign_key "plan_products", "companies", on_delete: :cascade
  add_foreign_key "plan_products", "plans", on_delete: :cascade
  add_foreign_key "plan_products", "products", on_delete: :cascade
  add_foreign_key "plan_schedules", "companies", on_delete: :cascade
  add_foreign_key "plan_schedules", "plans", on_delete: :cascade
  add_foreign_key "plan_schedules", "stores", on_delete: :cascade
  add_foreign_key "plan_schedules", "users"
  add_foreign_key "plans", "categories", on_delete: :cascade
  add_foreign_key "plans", "companies", on_delete: :cascade
  add_foreign_key "plans", "stores", on_delete: :cascade
  add_foreign_key "plans", "users"
  add_foreign_key "product_materials", "companies"
  add_foreign_key "product_materials", "materials", on_delete: :cascade
  add_foreign_key "product_materials", "products", on_delete: :cascade
  add_foreign_key "product_materials", "units"
  add_foreign_key "products", "categories", on_delete: :cascade
  add_foreign_key "products", "companies", on_delete: :cascade
  add_foreign_key "products", "stores", on_delete: :cascade
  add_foreign_key "products", "users"
  add_foreign_key "stores", "companies", on_delete: :cascade
  add_foreign_key "units", "companies", on_delete: :cascade
  add_foreign_key "units", "stores", on_delete: :cascade
  add_foreign_key "units", "users"
  add_foreign_key "users", "companies", on_delete: :cascade
  add_foreign_key "users", "stores", on_delete: :nullify
  add_foreign_key "versions", "companies"
  add_foreign_key "versions", "stores"
end
