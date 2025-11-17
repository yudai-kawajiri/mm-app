// Plan Assignment Controller
//
// 計画割り当てモーダルのStimulusコントローラー
//
// 使用例:
//   <div
//     class="modal"
//     data-controller="plan-assignment"
//     data-bs-backdrop="static"
//   >
//     <!-- カテゴリ選択 -->
//     <select
//       data-plan-assignment-target="category"
//       data-action="change->plan-assignment#updatePlans"
//     >
//       <option value="">カテゴリを選択</option>
//     </select>
//
//     <!-- 計画選択 -->
//     <select
//       data-plan-assignment-target="plan"
//       data-action="change->plan-assignment#updateRevenue"
//     >
//       <option value="">計画を選択</option>
//     </select>
//
//     <!-- 予定売上表示 -->
//     <input
//       type="text"
//       data-plan-assignment-target="plannedRevenue"
//       readonly
//     />
//   </div>
//
// 機能:
// - カテゴリ選択に応じた計画の動的読み込み
// - 計画選択時の予定売上自動表示
// - モーダル開閉時の状態リセット
// - グローバル変数 window.plansByCategory からデータ取得
//
// Targets:
// - category: カテゴリセレクトボックス
// - plan: 計画セレクトボックス
// - plannedRevenue: 予定売上表示フィールド
// - categoryGroup: カテゴリ選択グループ
// - planGroup: 計画選択グループ
//
// 必須データ:
// - window.plansByCategory: サーバーから渡される計画データ
//
// 翻訳キー:
// - plan_assignment.select_plan: 計画選択プレースホルダー

import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"
import Logger from "../utils/logger"

// 定数定義
const GLOBAL_DATA = {
  PLANS_BY_CATEGORY: 'plansByCategory'
}

const EVENT_TYPE = {
  MODAL_SHOW: 'show.bs.modal'
}

const DISPLAY_STYLE = {
  SHOW: 'block',
  HIDE: 'none'
}

const ELEMENT_PROPERTY = {
  DISABLED: 'disabled'
}

const DATA_ATTRIBUTE = {
  REVENUE: 'revenue'
}

const HTML_ELEMENT = {
  OPTION: 'option'
}

const HTML_ATTRIBUTE = {
  VALUE: 'value'
}

const I18N_KEYS = {
  SELECT_PLAN: 'plan_assignment.select_plan'
}

const DEFAULT_VALUE = {
  EMPTY_STRING: '',
  ZERO: 0,
  EMPTY_OBJECT: {}
}

const ARRAY_INDEX = {
  FIRST: 0
}

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'Plan assignment controller connected',
  MODAL_OPENING: 'Modal opening (show.bs.modal)',
  LOADED_PLANS_DATA: 'Loaded plansData:',
  AVAILABLE_CATEGORIES: 'Available categories:',
  RESET_MODAL: 'Reset modal',
  CATEGORY_SELECTED: 'Category selected:',
  PLAN_TARGET_NOT_FOUND: 'Plan target not found',
  NO_CATEGORY_SELECTED: 'No category selected, hiding plan dropdown',
  PLANS_FOR_CATEGORY: (category) => `Plans for category "${category}":`,
  NO_PLANS_FOUND: (category) => `No plans found for category: ${category}`,
  ADDED_PLANS: (count) => `Added ${count} plans to dropdown`,
  PLAN_SELECTED: 'Plan selected:',
  NO_PLAN_SELECTED: 'No plan selected',
  EXPECTED_REVENUE: 'Expected revenue:',
  UPDATED_REVENUE_FIELD: 'Updated planned revenue field to:'
}

export default class extends Controller {
  static targets = ["category", "plan", "plannedRevenue", "categoryGroup", "planGroup"]

  // コントローラー接続時の処理
  // 初期データを読み込み、モーダル開閉イベントをリスン
  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)
    this.loadPlansData()

    // モーダルが開かれるたびにデータを再読み込み
    this.element.addEventListener(EVENT_TYPE.MODAL_SHOW, () => {
      Logger.log(LOG_MESSAGES.MODAL_OPENING)
      this.loadPlansData()
      this.resetModal()
    })
  }

  // データ読み込みメソッド
  // window.plansByCategory からカテゴリ別の計画データを読み込む
  // connect と show.bs.modal で共通使用
  loadPlansData() {
    this.plansData = window[GLOBAL_DATA.PLANS_BY_CATEGORY] || DEFAULT_VALUE.EMPTY_OBJECT
    Logger.log(LOG_MESSAGES.LOADED_PLANS_DATA, this.plansData)
    Logger.log(LOG_MESSAGES.AVAILABLE_CATEGORIES, Object.keys(this.plansData))
  }

  // モーダルリセット処理
  // モーダルを初期状態に戻す:
  // - カテゴリと計画の選択をクリア
  // - 予定売上をクリア
  // - カテゴリグループを表示、計画グループを非表示
  resetModal() {
    Logger.log(LOG_MESSAGES.RESET_MODAL)

    // カテゴリと計画の選択をリセット
    if (this.hasCategoryTarget) {
      this.categoryTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }
    if (this.hasPlanTarget) {
      this.planTarget.innerHTML = this.createPlanPlaceholder()
      this.planTarget[ELEMENT_PROPERTY.DISABLED] = true
    }
    if (this.hasPlannedRevenueTarget) {
      this.plannedRevenueTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }

    // カテゴリグループを表示、計画グループを非表示
    if (this.hasCategoryGroupTarget) {
      this.categoryGroupTarget.style.display = DISPLAY_STYLE.SHOW
    }
    if (this.hasPlanGroupTarget) {
      this.planGroupTarget.style.display = DISPLAY_STYLE.HIDE
    }
  }

  // 計画選択プレースホルダーを生成
  createPlanPlaceholder() {
    return `<option ${HTML_ATTRIBUTE.VALUE}="${DEFAULT_VALUE.EMPTY_STRING}">${i18n.t(I18N_KEYS.SELECT_PLAN)}</option>`
  }

  // カテゴリ選択時の処理
  // 選択されたカテゴリに対応する計画を計画セレクトボックスに追加する
  // 計画がある場合は計画グループを表示
  updatePlans(event) {
    const category = event.target.value
    Logger.log(LOG_MESSAGES.CATEGORY_SELECTED, category)

    if (!this.hasPlanTarget) {
      Logger.warn(LOG_MESSAGES.PLAN_TARGET_NOT_FOUND)
      return
    }

    // 計画ドロップダウンをクリア
    this.planTarget.innerHTML = this.createPlanPlaceholder()

    if (!category) {
      this.planTarget[ELEMENT_PROPERTY.DISABLED] = true
      if (this.hasPlanGroupTarget) {
        this.planGroupTarget.style.display = DISPLAY_STYLE.HIDE
      }
      Logger.log(LOG_MESSAGES.NO_CATEGORY_SELECTED)
      return
    }

    // カテゴリに対応する計画を取得
    const plans = this.plansData[category]
    Logger.log(LOG_MESSAGES.PLANS_FOR_CATEGORY(category), plans)

    if (!plans || plans.length === DEFAULT_VALUE.ZERO) {
      Logger.warn(LOG_MESSAGES.NO_PLANS_FOUND(category))
      this.planTarget[ELEMENT_PROPERTY.DISABLED] = true
      return
    }

    // 計画を追加
    plans.forEach(plan => {
      const option = document.createElement(HTML_ELEMENT.OPTION)
      option.value = plan.id
      option.textContent = plan.name
      option.dataset[DATA_ATTRIBUTE.REVENUE] = plan.expected_revenue || DEFAULT_VALUE.ZERO
      this.planTarget.appendChild(option)
    })

    this.planTarget[ELEMENT_PROPERTY.DISABLED] = false

    // 計画グループを表示
    if (this.hasPlanGroupTarget) {
      this.planGroupTarget.style.display = DISPLAY_STYLE.SHOW
    }

    Logger.log(LOG_MESSAGES.ADDED_PLANS(plans.length))
  }

  // 計画選択時の処理
  // 選択された計画の予定売上を予定売上フィールドに表示する
  updateRevenue(event) {
    const selectedOption = event.target.selectedOptions[ARRAY_INDEX.FIRST]
    Logger.log(LOG_MESSAGES.PLAN_SELECTED, selectedOption)

    if (!selectedOption) {
      Logger.warn(LOG_MESSAGES.NO_PLAN_SELECTED)
      return
    }

    const revenue = selectedOption.dataset[DATA_ATTRIBUTE.REVENUE] || DEFAULT_VALUE.ZERO
    Logger.log(LOG_MESSAGES.EXPECTED_REVENUE, revenue)

    if (this.hasPlannedRevenueTarget) {
      this.plannedRevenueTarget.value = revenue
      Logger.log(LOG_MESSAGES.UPDATED_REVENUE_FIELD, revenue)
    }
  }
}
