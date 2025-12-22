// Stimulus コントローラーの一括登録
import { application } from "controllers/application"

// Admin Controllers
import AdminUserRoleController from "controllers/admin/user_role_controller"

// Form Controllers
import FormNestedFormController from "controllers/form/nested_form_controller"
import FormNestedFormItemController from "controllers/form/nested_form_item_controller"
import FormSubmitController from "controllers/form/submit_controller"

// Input Controllers
import CharacterCounterController from "controllers/input/character_counter_controller"
import NumberInputController from "controllers/input/number_input_controller"

// Management Controllers
import OrderGroupController from "controllers/management/order_group_controller"
import PlanAssignmentController from "controllers/management/plan_assignment_controller"
import AssignPlanInfoController from "controllers/management/assign_plan_info_controller"
import AssignPlanModalController from "controllers/management/assign_plan_modal_controller"
import DailyDetailsController from "controllers/management/daily_details_controller"
import DailyTargetModalController from "controllers/management/daily_target_modal_controller"
import ActualRevenueModalController from "controllers/management/actual_revenue_modal_controller"

// Resources Controllers
import ResourcesPlanProductRowController from "controllers/resources/plan-product/row_controller"
import ResourcesPlanProductTotalsController from "controllers/resources/plan-product/totals_controller"
import ResourcesPlanProductSyncController from "controllers/resources/plan-product/sync_controller"
import ResourcesProductMaterialMaterialController from "controllers/resources/product-material/material_controller"
import ResourcesMaterialFormController from "controllers/resources/material_form_controller"

// UI Controllers
import FlashController from "controllers/ui/flash_controller"
import ImagePreviewController from "controllers/ui/image_preview_controller"
import SortableTableController from "controllers/ui/sortable_table_controller"
import TabsCategoryTabsController from "controllers/ui/tabs/category_tabs_controller"

// Help Controllers
import HelpSearchController from "controllers/help_search_controller"
import VideoModalController from "controllers/video_modal_controller"

// Other Controllers
import ResourceSearchController from "controllers/resource_search_controller"
import WelcomeModalController from "controllers/welcome_modal_controller"
import SlugRedirectController from "controllers/slug_redirect_controller"

// コントローラー登録
application.register("admin--user-role", AdminUserRoleController)
application.register("form--nested-form", FormNestedFormController)
application.register("form--nested-form-item", FormNestedFormItemController)
application.register("form--submit", FormSubmitController)
application.register("input--character-counter", CharacterCounterController)
application.register("input--number-input", NumberInputController)
application.register("order-group", OrderGroupController)
application.register("plan-assignment", PlanAssignmentController)
application.register("management--assign-plan-info", AssignPlanInfoController)
application.register("management--assign-plan-modal", AssignPlanModalController)
application.register("management--daily-details", DailyDetailsController)
application.register("management--daily-target-modal", DailyTargetModalController)
application.register("management--actual-revenue-modal", ActualRevenueModalController)
application.register("resources--plan-product--row", ResourcesPlanProductRowController)
application.register("resources--plan-product--totals", ResourcesPlanProductTotalsController)
application.register("resources--plan-product--sync", ResourcesPlanProductSyncController)
application.register("resources--product-material--material", ResourcesProductMaterialMaterialController)
application.register("resources--material-form", ResourcesMaterialFormController)
application.register("flash", FlashController)
application.register("image-preview", ImagePreviewController)
application.register("sortable-table", SortableTableController)
application.register("tabs--category-tabs", TabsCategoryTabsController)
application.register("help-search", HelpSearchController)
application.register("video-modal", VideoModalController)
application.register("resource-search", ResourceSearchController)
application.register("welcome-modal", WelcomeModalController)
application.register("slug-redirect", SlugRedirectController)
