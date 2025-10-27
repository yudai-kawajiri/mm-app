// app/javascript/controllers/index.js

import { application } from "controllers/application"

// 💡 修正: ファイルパスの先頭に 'controllers/' を追加し、
//       importmapにマッピングされた名前でインポートする
//       （これにより、index.jsがimportmapを介してファイルをロードします）

// Form Controllers
import FormNestedFormController from "controllers/form/nested_form_controller" // 修正
import FormNestedFormItemController from "controllers/form/nested_form_item_controller" // 修正
import FormSubmitController from "controllers/form/submit_controller" // 修正

// Tabs Controllers
import TabsCategoryTabsController from "controllers/tabs/category_tabs_controller" // 修正

// Resources - Plan Product Controllers
import ResourcesPlanProductRowController from "controllers/resources/plan-product/row_controller" // 修正
import ResourcesPlanProductTotalsController from "controllers/resources/plan-product/totals_controller" // 修正
import ResourcesPlanProductSyncController from "controllers/resources/plan-product/sync_controller" // 修正

// Resources - Product Material Controllers
import ResourcesProductMaterialMaterialController from "controllers/resources/product-material/material_controller" // 修正

// 手動登録
application.register("form--nested-form", FormNestedFormController)
application.register("form--nested-form-item", FormNestedFormItemController)
application.register("form--submit", FormSubmitController)
application.register("tabs--category-tabs", TabsCategoryTabsController)
application.register("resources--plan-product--row", ResourcesPlanProductRowController)
application.register("resources--plan-product--totals", ResourcesPlanProductTotalsController)
application.register("resources--plan-product--sync", ResourcesPlanProductSyncController)
application.register("resources--product-material--material", ResourcesProductMaterialMaterialController)
