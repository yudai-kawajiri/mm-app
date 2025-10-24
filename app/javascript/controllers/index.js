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

// 商品行の小計とAPI呼び出しを制御
import PlanProductController from "./plan_product_controller"
application.register("plan-product", PlanProductController)

// 総合計とカテゴリ合計を制御
import PlanProductsController from "./plan_products_controller"
application.register("plan-products", PlanProductsController)

// 単位と単位分量を取得
import ProductMaterialController from "./product_material_controller"
application.register("product-material", ProductMaterialController)