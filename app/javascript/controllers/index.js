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