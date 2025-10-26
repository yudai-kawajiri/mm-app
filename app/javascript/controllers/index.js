// import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
// eagerLoadControllersFrom("controllers", application)

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// 原材料を追加」ボタンを制御する、親のコントローラー
import NestedFormController from "./nested_form_controller"
application.register("nested-form", NestedFormController)

// 原材料1行（削除ボタン）を制御する、子のコントローラー
import NestedFormItemController from "./nested_form_item_controller"
application.register("nested-form-item", NestedFormItemController)

// 金額のロジックを制御
import PlanProductController from "./plan_product_controller"
application.register("plan-product", PlanProductController)

// 単位と単位分量を取得
import ProductMaterialController from "./product_material_controller"
application.register("product-material", ProductMaterialController)

// 💡 [追加] カテゴリタブの動的追加・管理を制御
import CategoryTabManagerController from "./category_tab_manager_controller"
application.register("category-tab-manager", CategoryTabManagerController)

import PlanProductTabsController from "./plan_product_tabs_controller"
application.register("plan-product-tabs", PlanProductTabsController)

// 💡 デバッグ用（後で削除可能）
window.Stimulus = application

export { application }
