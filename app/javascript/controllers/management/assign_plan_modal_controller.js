// Assign Plan Modal Controller
//
// 計画割当モーダルの制御コントローラー
//
// 使用例:
//   <div
//     class="modal"
//     data-controller="management--assign-plan-modal"
//     data-management--assign-plan-modal-plans-value="<%= @plans_by_category.to_json %>"
//   >
//     <!-- モーダルの内容 -->
//   </div>
//
// 機能:
// - カテゴリー選択に応じた計画の動的読み込み
// - 計画選択時の商品表示と予定売上計算
// - モーダル開閉時の状態リセット
// - 編集モードと新規作成モードの切り替え
//
// Targets:
// - categorySelect: カテゴリーセレクトボックス
// - planSelect: 計画セレクトボックス
// - productsAdjustSection: 商品調整セクション
// - productsContainer: 商品一覧コンテナ
// - totalCostDisplay: 合計金額表示
// - plannedRevenue: 予定売上hidden field
// - modalTitle: モーダルタイトル
// - submitBtn: 送信ボタン
// - form: フォーム要素
// - dateDisplay: 日付表示
// - dateHidden: 日付hidden field
// - infoAlert: 情報アラート

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"
import CurrencyFormatter from "utils/currency_formatter"

// 定数定義
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
  SCHEDULE_ID: 'scheduleId',
  PLAN_ID: 'planId',
  CATEGORY_NAME: 'categoryName',
  PLANNED_REVENUE: 'plannedRevenue',
  DATE_DISPLAY: 'dateDisplay',
  DATE: 'date',
  SNAPSHOT: 'snapshot',
  REVENUE: 'revenue',
  PRODUCTS: 'products',
  PRICE: 'price',
  PRODUCT_ID: 'productId',
  SUBTOTAL: 'subtotal'
}

const HTML_ELEMENT = {
  OPTION: 'option',
  INPUT: 'input',
  DIV: 'div'
}

const HTML_ATTRIBUTE = {
  VALUE: 'value',
  TYPE: 'type',
  NAME: 'name'
}

const INPUT_TYPE = {
  HIDDEN: 'hidden',
  NUMBER: 'number'
}

const HTTP_METHOD = {
  PATCH: 'patch'
}

const DEFAULT_VALUE = {
  EMPTY_STRING: '',
  ZERO: 0,
  EMPTY_ARRAY: []
}

const ARRAY_INDEX = {
  FIRST: 0
}

const URL_PATH = {
  PLAN_SCHEDULES: '/management/plan_schedules'
}

const SELECTOR = {
  CSRF_TOKEN: 'meta[name="csrf-token"]',
  METHOD_INPUT: 'input[name="_method"]',
  TOKEN_INPUT: 'input[name="authenticity_token"]',
  PRODUCT_INPUT: (productId) => `input[data-product-id="${productId}"]`,
  PRODUCTS_INPUTS: '#productsContainer input[type="number"]',
  SUBTOTAL_ELEMENT: (productId) => `[data-subtotal="${productId}"]`
}

const CSS_CLASS = {
  ROW: 'row mb-2 align-items-center',
  COL_MD_6: 'col-md-6',
  COL_MD_3: 'col-md-3',
  COL_MD_3_TEXT_END: 'col-md-3 text-end',
  FORM_LABEL: 'form-label mb-0',
  FORM_CONTROL: 'form-control form-control-sm',
  TEXT_MUTED: 'text-muted'
}

const PLAN_STATUS = {
  COMPLETED: 'completed'
}

const TIMEOUT_DELAY = {
  PLAN_SELECT: 50,
  SNAPSHOT_APPLY: 150
}

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'Assign plan modal controller connected',
  MODAL_OPENING: 'Modal opening',
  CATEGORY_CHANGED: 'Category changed:',
  PLANS_FOUND: 'Plans found:',
  AVAILABLE_PLANS: 'Available plans:',
  PLAN_CHANGED: 'Plan changed',
  PRODUCTS_DISPLAYED: 'Products displayed:',
  TOTAL_COST_UPDATED: 'Total cost updated:',
  MODAL_DATA_SET: 'Modal data set for schedule:',
  EDIT_MODE: 'Edit mode',
  CREATE_MODE: 'Create mode'
}

export default class extends Controller {
  static targets = [
    "categorySelect",
    "planSelect",
    "productsAdjustSection",
    "productsContainer",
    "totalCostDisplay",
    "plannedRevenue",
    "modalTitle",
    "submitBtn",
    "form",
    "dateDisplay",
    "dateHidden",
    "infoAlert"
  ]

  static values = {
    plans: Object,
    i18nSelectPlaceholder: String,
    i18nSelectPlanAfterCategory: String,
    i18nNoAvailablePlans: String,
    i18nAlertPlanUnavailable: String,
    i18nEditTitle: String,
    i18nAddTitle: String,
    i18nCreateLabel: String,
    i18nUpdateLabel: String,
    i18nNoProducts: String
  }

  // コントローラー接続時の処理
  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)

    // モーダル表示時のイベントリスナー
    this.element.addEventListener(EVENT_TYPE.MODAL_SHOW, (event) => {
      Logger.log(LOG_MESSAGES.MODAL_OPENING)
      this.handleModalShow(event)
    })

    // 現在の商品データを初期化
    this.currentPlanProducts = DEFAULT_VALUE.EMPTY_ARRAY
  }

  // モーダル表示時の処理
  handleModalShow(event) {
    const button = event.relatedTarget
    if (button) {
      this.setModalData(button)
    }
  }

  // モーダルデータ設定
  setModalData(button) {
    const scheduleId = button.dataset[DATA_ATTRIBUTE.SCHEDULE_ID]
    const planId = button.dataset[DATA_ATTRIBUTE.PLAN_ID]
    const categoryName = button.dataset[DATA_ATTRIBUTE.CATEGORY_NAME]
    const plannedRevenue = button.dataset[DATA_ATTRIBUTE.PLANNED_REVENUE]
    const dateDisplay = button.dataset[DATA_ATTRIBUTE.DATE_DISPLAY]
    const date = button.dataset[DATA_ATTRIBUTE.DATE]
    const snapshot = button.dataset[DATA_ATTRIBUTE.SNAPSHOT]

    Logger.log(LOG_MESSAGES.MODAL_DATA_SET, scheduleId)

    // 日付設定
    if (this.hasDateDisplayTarget) {
      this.dateDisplayTarget.value = dateDisplay || DEFAULT_VALUE.EMPTY_STRING
    }
    if (this.hasDateHiddenTarget) {
      this.dateHiddenTarget.value = date || DEFAULT_VALUE.EMPTY_STRING
    }

    // 初期状態リセット
    this.resetProductsSection()
    this.showInfoAlert()

    if (scheduleId) {
      Logger.log(LOG_MESSAGES.EDIT_MODE)
      this.setupEditMode(scheduleId, categoryName, planId, plannedRevenue, snapshot)
    } else {
      Logger.log(LOG_MESSAGES.CREATE_MODE)
      this.setupCreateMode()
    }
  }

  // 編集モード設定
  setupEditMode(scheduleId, categoryName, planId, plannedRevenue, snapshot) {
    // タイトルとボタン
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = this.i18nEditTitleValue
    }
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.value = this.i18nUpdateLabelValue
    }

    // フォームアクション
    if (this.hasFormTarget) {
      this.formTarget.action = `${URL_PATH.PLAN_SCHEDULES}/${scheduleId}`
      this.updateMethodInput(HTTP_METHOD.PATCH)
      this.updateCsrfToken()
    }

    // カテゴリーと計画を設定
    if (categoryName && this.hasCategorySelectTarget) {
      this.categorySelectTarget.value = categoryName
      this.handleCategoryChange({ target: this.categorySelectTarget })

      setTimeout(() => {
        if (planId && this.hasPlanSelectTarget) {
          this.planSelectTarget.value = planId

          if (!this.planSelectTarget.value || this.planSelectTarget.value === DEFAULT_VALUE.EMPTY_STRING) {
            alert(this.i18nAlertPlanUnavailableValue)
          } else {
            this.handlePlanChange({ target: this.planSelectTarget })

            // スナップショット適用
            if (snapshot && snapshot !== 'null' && snapshot !== 'undefined') {
              setTimeout(() => {
                this.applySnapshot(snapshot)
              }, TIMEOUT_DELAY.SNAPSHOT_APPLY)
            }
          }
        }
      }, TIMEOUT_DELAY.PLAN_SELECT)
    }

    // 予定売上設定
    if (this.hasPlannedRevenueTarget) {
      this.plannedRevenueTarget.value = plannedRevenue || DEFAULT_VALUE.ZERO
    }
  }

  // 新規作成モード設定
  setupCreateMode() {
    // タイトルとボタン
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = this.i18nAddTitleValue
    }
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.value = this.i18nCreateLabelValue
    }

    // フォームアクション
    if (this.hasFormTarget) {
      this.formTarget.action = URL_PATH.PLAN_SCHEDULES
      this.removeMethodInput()
      this.updateCsrfToken()
    }

    // セレクトボックスリセット
    if (this.hasCategorySelectTarget) {
      this.categorySelectTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }
    if (this.hasPlanSelectTarget) {
      this.planSelectTarget.innerHTML = `<option ${HTML_ATTRIBUTE.VALUE}="${DEFAULT_VALUE.EMPTY_STRING}">${this.i18nSelectPlanAfterCategoryValue}</option>`
      this.planSelectTarget[ELEMENT_PROPERTY.DISABLED] = true
    }

    // 予定売上リセット
    if (this.hasPlannedRevenueTarget) {
      this.plannedRevenueTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }
  }

  // カテゴリー変更処理
  handleCategoryChange(event) {
    const category = event.target.value
    Logger.log(LOG_MESSAGES.CATEGORY_CHANGED, category)

    this.resetProductsSection()
    this.showInfoAlert()

    if (!category) {
      this.resetPlanSelect()
      if (this.hasPlannedRevenueTarget) {
        this.plannedRevenueTarget.value = DEFAULT_VALUE.EMPTY_STRING
      }
      return
    }

    this.updatePlanOptions(category)
  }

  // 計画オプション更新
  updatePlanOptions(category) {
    if (!this.hasPlanSelectTarget) return

    this.planSelectTarget.innerHTML = `<option ${HTML_ATTRIBUTE.VALUE}="${DEFAULT_VALUE.EMPTY_STRING}">${this.i18nSelectPlaceholderValue}</option>`

    const plans = this.plansValue[category]
    Logger.log(LOG_MESSAGES.PLANS_FOUND, plans)

    if (!plans || plans.length === DEFAULT_VALUE.ZERO) {
      this.planSelectTarget[ELEMENT_PROPERTY.DISABLED] = true
      return
    }

    const availablePlans = plans.filter(plan => plan.status !== PLAN_STATUS.COMPLETED)
    Logger.log(LOG_MESSAGES.AVAILABLE_PLANS, availablePlans)

    if (availablePlans.length === DEFAULT_VALUE.ZERO) {
      this.planSelectTarget.innerHTML = `<option ${HTML_ATTRIBUTE.VALUE}="${DEFAULT_VALUE.EMPTY_STRING}">${this.i18nNoAvailablePlansValue}</option>`
      this.planSelectTarget[ELEMENT_PROPERTY.DISABLED] = true
      return
    }

    availablePlans.forEach(plan => {
      const option = document.createElement(HTML_ELEMENT.OPTION)
      option.value = plan.id
      option.textContent = plan.name
      option.dataset[DATA_ATTRIBUTE.REVENUE] = plan.expected_revenue || DEFAULT_VALUE.ZERO
      option.dataset[DATA_ATTRIBUTE.PRODUCTS] = JSON.stringify(plan.plan_products)
      this.planSelectTarget.appendChild(option)
    })

    this.planSelectTarget[ELEMENT_PROPERTY.DISABLED] = false
  }

  // 計画変更処理
  handlePlanChange(event) {
    const selectedOption = event.target.selectedOptions[ARRAY_INDEX.FIRST]
    Logger.log(LOG_MESSAGES.PLAN_CHANGED)

    if (selectedOption && selectedOption.value) {
      const products = JSON.parse(selectedOption.dataset[DATA_ATTRIBUTE.PRODUCTS] || '[]')
      this.currentPlanProducts = products
      this.displayProducts(products)
      this.hideInfoAlert()
    } else {
      this.resetProductsSection()
      if (this.hasPlannedRevenueTarget) {
        this.plannedRevenueTarget.value = DEFAULT_VALUE.EMPTY_STRING
      }
      this.showInfoAlert()
    }
  }

  // 商品表示
  displayProducts(products) {
    if (!this.hasProductsContainerTarget) return

    this.productsContainerTarget.innerHTML = DEFAULT_VALUE.EMPTY_STRING

    if (products.length === DEFAULT_VALUE.ZERO) {
      this.productsContainerTarget.innerHTML = `<p class="${CSS_CLASS.TEXT_MUTED}">${this.i18nNoProductsValue}</p>`
      this.showProductsSection()
      return
    }

    Logger.log(LOG_MESSAGES.PRODUCTS_DISPLAYED, products)

    products.forEach((product) => {
      const subtotal = product.price * product.production_count
      const row = document.createElement(HTML_ELEMENT.DIV)
      row.className = CSS_CLASS.ROW

      row.innerHTML = `
        <div class="${CSS_CLASS.COL_MD_6}">
          <label class="${CSS_CLASS.FORM_LABEL}">${product.product_name}</label>
        </div>
        <div class="${CSS_CLASS.COL_MD_3}">
          <input type="${INPUT_TYPE.NUMBER}"
                 class="${CSS_CLASS.FORM_CONTROL}"
                 name="plan_schedule[products][${product.product_id}]"
                 value="${product.production_count}"
                 min="0"
                 data-price="${product.price}"
                 data-product-id="${product.product_id}">
        </div>
        <div class="${CSS_CLASS.COL_MD_3_TEXT_END}">
          <small class="${CSS_CLASS.TEXT_MUTED}" data-subtotal="${product.product_id}">${CurrencyFormatter.format(subtotal)}</small>
        </div>
      `

      this.productsContainerTarget.appendChild(row)

      const input = row.querySelector(`input[${HTML_ATTRIBUTE.TYPE}="${INPUT_TYPE.NUMBER}"]`)
      if (input) {
        input.addEventListener('change', () => this.updateTotalCost())
      }
    })

    this.showProductsSection()
    this.updateTotalCost()
  }

  // スナップショット適用
  applySnapshot(snapshotData) {
    try {
      const snapshot = JSON.parse(snapshotData)
      if (snapshot && Array.isArray(snapshot)) {
        snapshot.forEach(sp => {
          const input = document.querySelector(SELECTOR.PRODUCT_INPUT(sp.product_id))
          if (input) {
            input.value = sp.production_count
          }
        })
        this.updateTotalCost()
      }
    } catch (e) {
      Logger.error('Snapshot parse error:', e)
    }
  }

  // 合計金額更新
  updateTotalCost() {
    let total = DEFAULT_VALUE.ZERO

    document.querySelectorAll(SELECTOR.PRODUCTS_INPUTS).forEach(input => {
      const count = parseInt(input.value) || DEFAULT_VALUE.ZERO
      const price = parseInt(input.dataset[DATA_ATTRIBUTE.PRICE]) || DEFAULT_VALUE.ZERO
      const productId = input.dataset[DATA_ATTRIBUTE.PRODUCT_ID]
      const subtotal = count * price

      const subtotalElement = document.querySelector(SELECTOR.SUBTOTAL_ELEMENT(productId))
      if (subtotalElement) {
        subtotalElement.textContent = CurrencyFormatter.format(subtotal)
      }

      total += subtotal
    })

    Logger.log(LOG_MESSAGES.TOTAL_COST_UPDATED, total)

    if (this.hasTotalCostDisplayTarget) {
      this.totalCostDisplayTarget.textContent = CurrencyFormatter.format(total)
    }

    if (this.hasPlannedRevenueTarget) {
      this.plannedRevenueTarget.value = total
    }
  }

  // ヘルパーメソッド
  resetProductsSection() {
    this.hideProductsSection()
    if (this.hasProductsContainerTarget) {
      this.productsContainerTarget.innerHTML = DEFAULT_VALUE.EMPTY_STRING
    }
    this.currentPlanProducts = DEFAULT_VALUE.EMPTY_ARRAY
  }

  showProductsSection() {
    if (this.hasProductsAdjustSectionTarget) {
      this.productsAdjustSectionTarget.style.display = DISPLAY_STYLE.SHOW
    }
  }

  hideProductsSection() {
    if (this.hasProductsAdjustSectionTarget) {
      this.productsAdjustSectionTarget.style.display = DISPLAY_STYLE.HIDE
    }
  }

  resetPlanSelect() {
    if (this.hasPlanSelectTarget) {
      this.planSelectTarget.innerHTML = `<option ${HTML_ATTRIBUTE.VALUE}="${DEFAULT_VALUE.EMPTY_STRING}">${this.i18nSelectPlanAfterCategoryValue}</option>`
      this.planSelectTarget[ELEMENT_PROPERTY.DISABLED] = true
    }
  }

  showInfoAlert() {
    if (this.hasInfoAlertTarget) {
      this.infoAlertTarget.style.display = DISPLAY_STYLE.SHOW
    }
  }

  hideInfoAlert() {
    if (this.hasInfoAlertTarget) {
      this.infoAlertTarget.style.display = DISPLAY_STYLE.HIDE
    }
  }

  updateMethodInput(method) {
    if (!this.hasFormTarget) return

    let methodInput = this.formTarget.querySelector(SELECTOR.METHOD_INPUT)
    if (!methodInput) {
      methodInput = document.createElement(HTML_ELEMENT.INPUT)
      methodInput.type = INPUT_TYPE.HIDDEN
      methodInput.name = '_method'
      this.formTarget.appendChild(methodInput)
    }
    methodInput.value = method
  }

  removeMethodInput() {
    if (!this.hasFormTarget) return

    const methodInput = this.formTarget.querySelector(SELECTOR.METHOD_INPUT)
    if (methodInput) {
      methodInput.remove()
    }
  }

  updateCsrfToken() {
    if (!this.hasFormTarget) return

    const csrfToken = document.querySelector(SELECTOR.CSRF_TOKEN).content
    let tokenInput = this.formTarget.querySelector(SELECTOR.TOKEN_INPUT)

    if (!tokenInput) {
      tokenInput = document.createElement(HTML_ELEMENT.INPUT)
      tokenInput.type = INPUT_TYPE.HIDDEN
      tokenInput.name = 'authenticity_token'
      this.formTarget.appendChild(tokenInput)
    }
    tokenInput.value = csrfToken
  }
}
