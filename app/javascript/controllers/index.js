import { application } from "controllers/application"

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

// UI Enhancement Controllers
import FlashController from "controllers/flash_controller"
import CharacterCounterController from "controllers/character_counter_controller"
import FormValidationController from "controllers/form_validation_controller"
import NumberInputController from "controllers/number_input_controller"
import ImagePreviewController from "controllers/image_preview_controller"

// 計画割り当てController
import PlanAssignmentController from "controllers/plan_assignment_controller"

//  Sortable Table Controller（ドラッグ&ドロップ並び替え）
import SortableTableController from "controllers/sortable_table_controller"

// Budget Chart Controller（予算グラフ表示）
import BudgetChartController from "controllers/budget_chart_controller"

// 手動登録
application.register("form--nested-form", FormNestedFormController)
application.register("form--nested-form-item", FormNestedFormItemController)
application.register("form--submit", FormSubmitController)
application.register("tabs--category-tabs", TabsCategoryTabsController)
application.register("resources--plan-product--row", ResourcesPlanProductRowController)
application.register("resources--plan-product--totals", ResourcesPlanProductTotalsController)
application.register("resources--plan-product--sync", ResourcesPlanProductSyncController)
application.register("resources--product-material--material", ResourcesProductMaterialMaterialController)
application.register("flash", FlashController)
application.register("character-counter", CharacterCounterController)
application.register("form-validation", FormValidationController)
application.register("number-input", NumberInputController)
application.register("image-preview", ImagePreviewController)

// 計画割り当てController登録
application.register("plan-assignment", PlanAssignmentController)

// Sortable Table Controller登録（ドラッグ&ドロップ並び替え）
application.register("sortable-table", SortableTableController)

// Budget Chart Controller登録（予算グラフ表示）
application.register("budget-chart", BudgetChartController)