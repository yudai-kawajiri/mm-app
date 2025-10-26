// app/javascript/controllers/index.js
// 移行期間用: 新旧両方のコントローラーを登録

import { Application } from "@hotwired/stimulus"

const application = Application.start()

application.debug = true

if (application.debug) {
  window.Stimulus = application
  console.log('Stimulus debug mode enabled')
}

// 【旧版】既存のコントローラー（ビューファイルが参照中）
import NestedFormControllerOld from "./form/nested_form_controller"
application.register("nested-form", NestedFormControllerOld)

import NestedFormItemControllerOld from "./form/nested_form_item_controller"
application.register("nested-form-item", NestedFormItemControllerOld)

import PlanProductController from "./plan_product_controller"
application.register("plan-product", PlanProductController)

import ProductMaterialController from "./product_material_controller"
application.register("product-material", ProductMaterialController)

import CategoryTabManagerController from "./category_tab_manager_controller"
application.register("category-tab-manager", CategoryTabManagerController)

import PlanProductTabsController from "./plan_product_tabs_controller"
application.register("plan-product-tabs", PlanProductTabsController)

console.log('旧版コントローラーを登録しました')

// 【新版】リファクタリング後のコントローラー

// フォーム関連
import SubmitController from "./form/submit_controller"
application.register("form--submit", SubmitController)

// タブ関連（統合版）
import CategoryTabsController from "./tabs/category_tabs_controller"
application.register("tabs--category-tabs", CategoryTabsController)

// Plan Product 関連（分割版）
import PlanProductRowController from "./resources/plan-product/row_controller"
application.register("resources--plan-product--row", PlanProductRowController)

import PlanProductTotalsController from "./resources/plan-product/totals_controller"
application.register("resources--plan-product--totals", PlanProductTotalsController)

import PlanProductSyncController from "./resources/plan-product/sync_controller"
application.register("resources--plan-product--sync", PlanProductSyncController)

// Product Material 関連（新版）
import ProductMaterialControllerNew from "./resources/product-material/material_controller"
application.register("resources--product-material--material", ProductMaterialControllerNew)

console.log('✅ 新版コントローラーを登録しました')

// デバッグ情報

if (application.debug) {
  const controllers = application.controllers.map(c => c.identifier).sort()
  console.log('📋 登録済みコントローラー:', controllers)
  console.log(`🔢 合計: ${controllers.length} 個`)
}

export { application }