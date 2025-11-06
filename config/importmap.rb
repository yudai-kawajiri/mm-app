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

# UI Enhancement Controllers（手動 pin）
pin "controllers/flash_controller", to: "controllers/flash_controller.js"
pin "controllers/character_counter_controller", to: "controllers/character_counter_controller.js"
pin "controllers/form_validation_controller", to: "controllers/form_validation_controller.js"
pin "controllers/number_input_controller", to: "controllers/number_input_controller.js"
pin "controllers/image_preview_controller", to: "controllers/image_preview_controller.js"

# 計画割り当て Controller
pin "controllers/plan_assignment_controller", to: "controllers/plan_assignment_controller.js"

#  Sortable Table Controller（ドラッグ&ドロップ並び替え）
pin "controllers/sortable_table_controller", to: "controllers/sortable_table_controller.js"

# Budget Chart Controller（予算グラフ表示）
pin "controllers/budget_chart_controller", to: "controllers/budget_chart_controller.js"

# Material Controllers（手動 pin）
pin "controllers/measurement_type_controller", to: "controllers/measurement_type_controller.js"
pin "controllers/order_group_controller", to: "controllers/order_group_controller.js"


# Utils（手動 pin）
pin "utils/logger", to: "utils/logger.js", preload: true
pin "utils/currency_formatter", to: "utils/currency_formatter.js", preload: true

# jQuery など
pin "jquery", to: "jquery.min.js", preload: true
pin "jquery_ujs", to: "jquery_ujs.js", preload: true
pin "cocoon", to: "cocoon.js", preload: true

# Sortable.js（ドラッグ&ドロップライブラリ）
pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/+esm"

# Chart.js
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.5.1/dist/chart.js"
pin "chart.js/auto", to: "https://ga.jspm.io/npm:chart.js@4.5.1/auto/auto.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.4/dist/color.esm.js"
