// Stimulus コントローラーの一括登録
//
// すべてのStimulusコントローラーをインポートし、アプリケーションに登録する
// コントローラー名は data-controller 属性で使用される識別子

import { application } from "controllers/application"

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

// Resources - Plan Product Controllers
import ResourcesPlanProductRowController from "controllers/resources/plan-product/row_controller"
import ResourcesPlanProductTotalsController from "controllers/resources/plan-product/totals_controller"
import ResourcesPlanProductSyncController from "controllers/resources/plan-product/sync_controller"

// Resources - Product Material Controllers
import ResourcesProductMaterialMaterialController from "controllers/resources/product-material/material_controller"

// Resources - Material Form Controller
import ResourcesMaterialFormController from "controllers/resources/material_form_controller"

// UI Controllers
import FlashController from "controllers/ui/flash_controller"
import FormValidationController from "controllers/form_validation_controller"
import ImagePreviewController from "controllers/ui/image_preview_controller"
import SortableTableController from "controllers/ui/sortable_table_controller"

// UI - Tabs Controllers
import TabsCategoryTabsController from "controllers/ui/tabs/category_tabs_controller"

// Help Controllers
import HelpSearchController from "controllers/help_search_controller"
import VideoModalController from "controllers/video_modal_controller"

// Resource Search Controller
import ResourceSearchController from "controllers/resource_search_controller"

// Welcome Modal Controller
import WelcomeModalController from "controllers/welcome_modal_controller"

// コントローラー名定数
// data-controller 属性で使用される識別子
const CONTROLLER_NAMES = {
  // Form
  FORM_NESTED_FORM: 'form--nested-form',
  FORM_NESTED_FORM_ITEM: 'form--nested-form-item',
  FORM_SUBMIT: 'form--submit',

  // Input
  CHARACTER_COUNTER: 'input--character-counter',
  NUMBER_INPUT: 'input--number-input',

  // Management
  ORDER_GROUP: 'order-group',
  PLAN_ASSIGNMENT: 'plan-assignment',
  ASSIGN_PLAN_INFO: 'management--assign-plan-info',
  ASSIGN_PLAN_MODAL: 'management--assign-plan-modal',
  DAILY_DETAILS: 'management--daily-details',
  DAILY_TARGET_MODAL: 'management--daily-target-modal',
  ACTUAL_REVENUE_MODAL: 'management--actual-revenue-modal',

  // Resources - Plan Product
  RESOURCES_PLAN_PRODUCT_ROW: 'resources--plan-product--row',
  RESOURCES_PLAN_PRODUCT_TOTALS: 'resources--plan-product--totals',
  RESOURCES_PLAN_PRODUCT_SYNC: 'resources--plan-product--sync',

  // Resources - Product Material
  RESOURCES_PRODUCT_MATERIAL_MATERIAL: 'resources--product-material--material',

  // Resources - Material Form
  RESOURCES_MATERIAL_FORM: 'resources--material-form',

  // UI
  FLASH: 'flash',
  FORM_VALIDATION: 'form-validation',
  IMAGE_PREVIEW: 'image-preview',
  SORTABLE_TABLE: 'sortable-table',

  // UI - Tabs
  TABS_CATEGORY_TABS: 'tabs--category-tabs',

  // Help
  HELP_SEARCH: 'help-search',
  VIDEO_MODAL: 'video-modal',

  // Resource Search
  RESOURCE_SEARCH: 'resource-search',

  // Welcome Modal
  WELCOME_MODAL: 'welcome-modal'
}

// コントローラー登録
// Form Controllers
application.register(CONTROLLER_NAMES.FORM_NESTED_FORM, FormNestedFormController)
application.register(CONTROLLER_NAMES.FORM_NESTED_FORM_ITEM, FormNestedFormItemController)
application.register(CONTROLLER_NAMES.FORM_SUBMIT, FormSubmitController)

// Input Controllers
application.register(CONTROLLER_NAMES.CHARACTER_COUNTER, CharacterCounterController)
application.register(CONTROLLER_NAMES.NUMBER_INPUT, NumberInputController)

// Management Controllers
application.register(CONTROLLER_NAMES.ORDER_GROUP, OrderGroupController)
application.register(CONTROLLER_NAMES.PLAN_ASSIGNMENT, PlanAssignmentController)
application.register(CONTROLLER_NAMES.ASSIGN_PLAN_INFO, AssignPlanInfoController)
application.register(CONTROLLER_NAMES.ASSIGN_PLAN_MODAL, AssignPlanModalController)
application.register(CONTROLLER_NAMES.DAILY_DETAILS, DailyDetailsController)
application.register(CONTROLLER_NAMES.DAILY_TARGET_MODAL, DailyTargetModalController)
application.register(CONTROLLER_NAMES.ACTUAL_REVENUE_MODAL, ActualRevenueModalController)

// Resources - Plan Product Controllers
application.register(CONTROLLER_NAMES.RESOURCES_PLAN_PRODUCT_ROW, ResourcesPlanProductRowController)
application.register(CONTROLLER_NAMES.RESOURCES_PLAN_PRODUCT_TOTALS, ResourcesPlanProductTotalsController)
application.register(CONTROLLER_NAMES.RESOURCES_PLAN_PRODUCT_SYNC, ResourcesPlanProductSyncController)

// Resources - Product Material Controllers
application.register(CONTROLLER_NAMES.RESOURCES_PRODUCT_MATERIAL_MATERIAL, ResourcesProductMaterialMaterialController)

// Resources - Material Form Controller
application.register(CONTROLLER_NAMES.RESOURCES_MATERIAL_FORM, ResourcesMaterialFormController)

// UI Controllers
application.register(CONTROLLER_NAMES.FLASH, FlashController)
application.register(CONTROLLER_NAMES.FORM_VALIDATION, FormValidationController)
application.register(CONTROLLER_NAMES.IMAGE_PREVIEW, ImagePreviewController)
application.register(CONTROLLER_NAMES.SORTABLE_TABLE, SortableTableController)

// UI - Tabs Controllers
application.register(CONTROLLER_NAMES.TABS_CATEGORY_TABS, TabsCategoryTabsController)

// Help Controllers
application.register(CONTROLLER_NAMES.HELP_SEARCH, HelpSearchController)
application.register(CONTROLLER_NAMES.VIDEO_MODAL, VideoModalController)

// Resource Search Controller
application.register(CONTROLLER_NAMES.RESOURCE_SEARCH, ResourceSearchController)

// Welcome Modal Controller
application.register(CONTROLLER_NAMES.WELCOME_MODAL, WelcomeModalController)
