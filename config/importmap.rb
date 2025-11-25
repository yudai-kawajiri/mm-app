# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Application Controllers
pin "controllers/index", to: "controllers/index.js", preload: true
pin "controllers/application", to: "controllers/application.js", preload: true

# Form Controllers
pin "controllers/form/nested_form_controller", to: "controllers/form/nested_form_controller.js"
pin "controllers/form/nested_form_item_controller", to: "controllers/form/nested_form_item_controller.js"
pin "controllers/form/submit_controller", to: "controllers/form/submit_controller.js"

# UI Controllers
pin "controllers/ui/tabs/category_tabs_controller", to: "controllers/ui/tabs/category_tabs_controller.js"
pin "controllers/ui/sortable_table_controller", to: "controllers/ui/sortable_table_controller.js"
pin "controllers/ui/flash_controller", to: "controllers/ui/flash_controller.js"
pin "controllers/ui/image_preview_controller", to: "controllers/ui/image_preview_controller.js"

# Input Controllers
pin "controllers/input/character_counter_controller", to: "controllers/input/character_counter_controller.js"
pin "controllers/input/number_input_controller", to: "controllers/input/number_input_controller.js"

# Management Controllers
pin "controllers/management/order_group_controller", to: "controllers/management/order_group_controller.js"
pin "controllers/management/plan_assignment_controller", to: "controllers/management/plan_assignment_controller.js"
pin "controllers/management/assign_plan_info_controller", to: "controllers/management/assign_plan_info_controller.js"

# Resources Controllers
pin "controllers/resources/plan-product/row_controller", to: "controllers/resources/plan-product/row_controller.js"
pin "controllers/resources/plan-product/totals_controller", to: "controllers/resources/plan-product/totals_controller.js"
pin "controllers/resources/plan-product/sync_controller", to: "controllers/resources/plan-product/sync_controller.js"
pin "controllers/resources/product-material/material_controller", to: "controllers/resources/product-material/material_controller.js"

# Form Validation Controller
pin "controllers/form_validation_controller", to: "controllers/form_validation_controller.js"

# Utility modules
pin "utils/logger", to: "utils/logger.js"
pin "utils/currency_formatter", to: "utils/currency_formatter.js"
pin "controllers/i18n", to: "controllers/i18n.js"

# External libraries
pin "cocoon", to: "cocoon.js", preload: true

# Sortable.js（ドラッグ&ドロップライブラリ）
pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/+esm"
