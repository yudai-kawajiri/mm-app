// app/javascript/controllers/index.js

import { application } from "controllers/application"

// 💡 修正: ファイルパスの先頭に 'controllers/' を追加し、
//       importmapにマッピングされた名前でインポートする
//       （これにより、index.jsがimportmapを介してファイルをロードします）

// Form Controllers
import FormNestedFormController from "controllers/form/nested_form_controller"
import FormNestedFormItemController from "controllers/form/nested_form_item_controller"
import FormSubmitController from "controllers/form/submit_controller"

// Tabs Controllers
import TabsCategoryTabsController from "controllers/tabs/category_tabs_controller"

// Resources - Plan Product Controllers
import ResourcesPlanProductRowController from "controllers/resources/plan-product/row_controller"
import ResourcesPlanProductTotalsController from "controllers/resources/plan-product/totals_controller"
import ResourcesPlanProductSyncController from "controllers/resources/plan-product/sync_controller"

// Resources - Product Material Controllers
import ResourcesProductMaterialMaterialController from "controllers/resources/product-material/material_controller"

// 🆕 Branch 8: UI Enhancement Controllers
import FlashController from "controllers/flash_controller"
import CharacterCounterController from "controllers/character_counter_controller"
import FormValidationController from "controllers/form_validation_controller"

// 手動登録
application.register("form--nested-form", FormNestedFormController)
application.register("form--nested-form-item", FormNestedFormItemController)
application.register("form--submit", FormSubmitController)
application.register("tabs--category-tabs", TabsCategoryTabsController)
application.register("resources--plan-product--row", ResourcesPlanProductRowController)
application.register("resources--plan-product--totals", ResourcesPlanProductTotalsController)
application.register("resources--plan-product--sync", ResourcesPlanProductSyncController)
application.register("resources--product-material--material", ResourcesProductMaterialMaterialController)

// 🆕 Branch 8: 新しいコントローラーを登録
application.register("flash", FlashController)
application.register("character-counter", CharacterCounterController)
application.register("form-validation", FormValidationController)
