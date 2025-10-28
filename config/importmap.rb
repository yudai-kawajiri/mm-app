# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Controllers - コアファイル（手動 pin）
pin "controllers/index", to: "controllers/index.js", preload: true
pin "controllers/application", to: "controllers/application.js", preload: true

# Controllers - Form（手動 pin）
pin "controllers/form/nested_form_controller", to: "controllers/form/nested_form_controller.js"
pin "controllers/form/nested_form_item_controller", to: "controllers/form/nested_form_item_controller.js"
pin "controllers/form/submit_controller", to: "controllers/form/submit_controller.js"

# Controllers - Tabs（手動 pin）
pin "controllers/tabs/category_tabs_controller", to: "controllers/tabs/category_tabs_controller.js"

# Controllers - Plan Product（手動 pin）
pin "controllers/resources/plan-product/row_controller", to: "controllers/resources/plan-product/row_controller.js"
pin "controllers/resources/plan-product/totals_controller", to: "controllers/resources/plan-product/totals_controller.js"
pin "controllers/resources/plan-product/sync_controller", to: "controllers/resources/plan-product/sync_controller.js"

# Controllers - Product Material（手動 pin）
pin "controllers/resources/product-material/material_controller", to: "controllers/resources/product-material/material_controller.js"

# 🆕 Branch 8: UI Enhancement Controllers（手動 pin）
pin "controllers/flash_controller", to: "controllers/flash_controller.js"
pin "controllers/character_counter_controller", to: "controllers/character_counter_controller.js"
pin "controllers/form_validation_controller", to: "controllers/form_validation_controller.js"

# Utils（手動 pin）
pin "utils/logger", to: "utils/logger.js", preload: true
pin "utils/currency_formatter", to: "utils/currency_formatter.js", preload: true

# jQuery など
pin "jquery", to: "jquery.min.js", preload: true
pin "jquery_ujs", to: "jquery_ujs.js", preload: true
pin "cocoon", to: "cocoon.js", preload: true
