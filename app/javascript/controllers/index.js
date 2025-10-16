// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application"
// import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
// eagerLoadControllersFrom("controllers", application)

// 原材料を追加」ボタンを制御する、親のコントローラー
import NestedFormController from "./nested_form_controller"
application.register("nested-form", NestedFormController)

// 原材料1行（削除ボタン）を制御する、子のコントローラー
import NestedFormItemController from "./nested_form_item_controller"
application.register("nested-form-item", NestedFormItemController)

// ⭐ 【追加】商品行の小計とAPI呼び出しを制御
import PlanProductController from "./plan_product_controller"
application.register("plan-product", PlanProductController)

// ⭐ 【追加】総合計とカテゴリ合計を制御
import PlanProductsController from "./plan_products_controller"
application.register("plan-products", PlanProductsController)