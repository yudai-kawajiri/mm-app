// Plan Product Row Controller
//
// 製造計画:商品行の計算コントローラー(子)
//
// 使用例:
//   <tr data-controller="resources--plan-product--row" data-resources--plan-product--row-price-value="1000">
//     <select data-resources--plan-product--row-target="productSelect" data-action="change->resources--plan-product--row#updateProduct">
//       <option value="">選択</option>
//     </select>
//     <input type="number" data-resources--plan-product--row-target="productionCount" data-action="input->resources--plan-product--row#calculate" />
//     <span data-resources--plan-product--row-target="priceDisplay">¥1,000</span>
//     <span data-resources--plan-product--row-target="subtotal">¥0</span>
//   </tr>
//
// 責務:
// - 商品選択時のAPI連携(価格・カテゴリー取得)
// - 数量×単価の小計計算
// - 親コントローラーへの再計算通知
// - 編集時の既存データ読み込み
//
// データフロー:
// 1. 商品選択 → updateProduct() → API取得 → 価格・カテゴリー設定
// 2. 数量入力 → calculate() → 小計計算 → 親に通知
// 3. 親コントローラー → getCurrentValues() → 値取得 → 合計計算
//
// Targets:
// - productSelect: 商品選択セレクトボックス
// - productIdHidden: 商品ID hidden フィールド（全てタブ用）
// - productNameDisplay: 商品名表示要素（全てタブ用）
// - productionCount: 製造数量入力フィールド
// - priceDisplay: 価格表示要素
// - subtotal: 小計表示要素
//
// Values:
// - price: 商品単価
// - categoryId: カテゴリーID
//
// 翻訳キー:
// - plans.errors.product_fetch_failed: 商品情報取得失敗メッセージ

import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"
import Logger from "utils/logger"
import CurrencyFormatter from "utils/currency_formatter"

// 定数定義
const DELAY_MS = {
  INITIAL_CALCULATION: 100,
  PARENT_NOTIFICATION: 100,
  ENABLE_INPUT_DELAY: 100
}

const DEFAULT_VALUE = {
  ZERO: 0,
  EMPTY_STRING: ''
}

const API_ENDPOINT = {
  PRODUCT_DETAILS: (productId) => `/api/v1/products/${productId}/fetch_plan_details`
}

const HTTP_STATUS = {
  OK_MIN: 200,
  OK_MAX: 299
}

const CONTROLLER_IDENTIFIER = {
  PARENT: 'resources--plan-product--totals'
}

const SELECTOR = {
  PARENT_CONTROLLER: '[data-controller~="resources--plan-product--totals"]'
}

const METHOD_NAME = {
  RECALCULATE: 'recalculate'
}

const EVENT_TYPE = {
  ROW_CALCULATED: 'row-calculated'
}

const I18N_KEYS = {
  PRODUCT_FETCH_FAILED: 'plans.errors.product_fetch_failed'
}

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'Plan product row controller connected',
  PRODUCT_ALREADY_SELECTED: (productId) => `Product already selected on connect: ${productId}`,
  NO_PRODUCT_SELECTED: 'No product selected yet',
  PRODUCT_SELECTED: (productId) => `Product selected: ${productId}`,
  FETCHING_PRODUCT_INFO: (productId) => `Fetching product info for: ${productId}`,
  PRODUCT_DATA_RECEIVED: 'Product data received:',
  PRICE_SET: (price, categoryId) => `Price set to: ${price}, Category: ${categoryId}`,
  PRODUCT_FETCH_ERROR: 'Product fetch error:',
  PRICE_DISPLAY_UPDATED: (formattedPrice) => `Price display updated: ${formattedPrice}`,
  PRICE_DISPLAY_TARGET_NOT_FOUND: 'Price display target not found',
  PRODUCT_RESET: 'Product reset',
  CALCULATE_STARTED: 'Calculate started',
  CALCULATION: (quantity, price, subtotal) => `${quantity} × ${price} = ${subtotal}`,
  QUANTITY: (value) => `Quantity: ${value}`,
  SUBTOTAL_UPDATED: (formattedSubtotal) => `Subtotal updated: ${formattedSubtotal}`,
  SUBTOTAL_TARGET_NOT_FOUND: 'Subtotal target not found',
  NOTIFYING_PARENT: 'Notifying parent to recalculate',
  CALLING_PARENT_RECALCULATE: 'Calling parent recalculate',
  PARENT_CONTROLLER_NOT_FOUND: 'Parent controller not found or invalid',
  PARENT_ELEMENT_NOT_FOUND: 'Parent element not found',
  SKIPPING_PRODUCT_DISABLE: 'Skipping product disabling: All tab or no category ID',
  TBODY_NOT_FOUND: 'tbody[data-category-id] not found',
  SELECTED_PRODUCT_IDS: (categoryId, ids) => `Selected product IDs in category ${categoryId}: ${ids}`,
  PRODUCT_DISABLED: (productId) => `Disabled product ID ${productId}`,
  PRODUCT_DISABLE_COMPLETED: 'Disabled selected products in same tab'
}

export default class extends Controller {
  static targets = ["productSelect", "productIdHidden", "productNameDisplay", "productionCount", "priceDisplay", "subtotal"]

  static values = {
    price: Number,
    categoryId: Number
  }

  // ============================================================
  // 初期化
  // ============================================================

  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)

    this.isCalculating = false

    let productId = null

    if (this.hasProductSelectTarget && this.productSelectTarget.value) {
      productId = this.productSelectTarget.value
    } else if (this.hasProductIdHiddenTarget && this.productIdHiddenTarget.value) {
      productId = this.productIdHiddenTarget.value
    } else if (this.element.dataset.productId) {
      productId = this.element.dataset.productId
    }

    if (productId) {
      Logger.log(LOG_MESSAGES.PRODUCT_ALREADY_SELECTED(productId))
      setTimeout(() => {
        this.enableInputFields()
        Logger.log('Production count input enabled after delay')
      }, DELAY_MS.ENABLE_INPUT_DELAY)
      this.fetchProductInfo(productId)
    } else {
      Logger.log(LOG_MESSAGES.NO_PRODUCT_SELECTED)
      this.disableInputFields()
      setTimeout(() => this.calculate(), DELAY_MS.INITIAL_CALCULATION)
    }

    setTimeout(() => {
      this.disableSelectedProductsInSameTab()
    }, 200)
  }

  // ============================================================
  // 商品選択時の処理
  // ============================================================

  async updateProduct(event) {
    const productId = event.target.value
    Logger.log(LOG_MESSAGES.PRODUCT_SELECTED(productId))

    if (!productId) {
      this.resetProduct()
      this.disableInputFields()
      return
    }

    this.enableInputFields()
    await this.fetchProductInfo(productId)

    this.disableSelectedProductsInSameTab()
  }

  async fetchProductInfo(productId) {
    try {
      Logger.log(LOG_MESSAGES.FETCHING_PRODUCT_INFO(productId))

      const response = await fetch(API_ENDPOINT.PRODUCT_DETAILS(productId))

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const product = await response.json()
      Logger.log(LOG_MESSAGES.PRODUCT_DATA_RECEIVED, product)

      this.priceValue = product.price || DEFAULT_VALUE.ZERO
      this.categoryIdValue = product.category_id || DEFAULT_VALUE.ZERO

      this.updatePriceDisplay()
      this.calculate()

      this.syncPriceToAllTab()

      Logger.log(LOG_MESSAGES.PRICE_SET(this.priceValue, this.categoryIdValue))
    } catch (error) {
      Logger.error(LOG_MESSAGES.PRODUCT_FETCH_ERROR, error)
      alert(i18n.t(I18N_KEYS.PRODUCT_FETCH_FAILED))
      this.resetProduct()
    }
  }

  updatePriceDisplay() {
    if (this.hasPriceDisplayTarget) {
      this.priceDisplayTarget.textContent = CurrencyFormatter.format(this.priceValue)
      Logger.log(LOG_MESSAGES.PRICE_DISPLAY_UPDATED(CurrencyFormatter.format(this.priceValue)))
    } else {
      Logger.warn(LOG_MESSAGES.PRICE_DISPLAY_TARGET_NOT_FOUND)
    }
  }

  resetProduct() {
    this.priceValue = DEFAULT_VALUE.ZERO
    this.categoryIdValue = DEFAULT_VALUE.ZERO
    this.updatePriceDisplay()

    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(DEFAULT_VALUE.ZERO)
    }

    this.calculate()
    Logger.log(LOG_MESSAGES.PRODUCT_RESET)
  }

  // ============================================================
  // 入力フィールドの有効化/無効化
  // ============================================================

  enableInputFields() {
    if (this.hasProductionCountTarget) {
      this.productionCountTarget.disabled = false
      Logger.log('Production count input enabled')
    }
  }

  disableInputFields() {
    if (this.hasProductionCountTarget) {
      this.productionCountTarget.disabled = true
      Logger.log('Production count input disabled')
    }
  }

  // ============================================================
  // 小計計算
  // ============================================================

  calculate() {
    if (this.isCalculating) return

    this.isCalculating = true
    Logger.log(LOG_MESSAGES.CALCULATE_STARTED)

    const quantity = this.getQuantity()
    const price = this.priceValue || DEFAULT_VALUE.ZERO
    const subtotal = quantity * price

    Logger.log(LOG_MESSAGES.CALCULATION(quantity, price, subtotal))

    this.updateSubtotal(subtotal)

    clearTimeout(this.notifyTimeout)
    this.notifyTimeout = setTimeout(() => {
      this.notifyParent()
      this.isCalculating = false
    }, DELAY_MS.PARENT_NOTIFICATION)
  }

  getQuantity() {
    if (!this.hasProductionCountTarget) return DEFAULT_VALUE.ZERO
    const value = parseFloat(this.productionCountTarget.value) || DEFAULT_VALUE.ZERO
    Logger.log(LOG_MESSAGES.QUANTITY(value))
    return value
  }

  updateSubtotal(subtotal) {
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(subtotal)
      Logger.log(LOG_MESSAGES.SUBTOTAL_UPDATED(CurrencyFormatter.format(subtotal)))
    } else {
      Logger.warn(LOG_MESSAGES.SUBTOTAL_TARGET_NOT_FOUND)
    }
  }

  notifyParent() {
    Logger.log(LOG_MESSAGES.NOTIFYING_PARENT)

    const parentElement = document.querySelector(SELECTOR.PARENT_CONTROLLER)
    if (parentElement) {
      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        CONTROLLER_IDENTIFIER.PARENT
      )
      if (parentController && parentController !== this && typeof parentController[METHOD_NAME.RECALCULATE] === 'function') {
        Logger.log(LOG_MESSAGES.CALLING_PARENT_RECALCULATE)
        parentController[METHOD_NAME.RECALCULATE]({ type: EVENT_TYPE.ROW_CALCULATED })
      } else {
        Logger.warn(LOG_MESSAGES.PARENT_CONTROLLER_NOT_FOUND)
      }
    } else {
      Logger.warn(LOG_MESSAGES.PARENT_ELEMENT_NOT_FOUND)
    }
  }

  // ============================================================
  // ALLタブへの同期
  // ============================================================

  syncPriceToAllTab() {
    const rowUniqueId = this.element.dataset.rowUniqueId
    if (!rowUniqueId) {
      Logger.warn('Row unique ID not found, cannot sync to ALL tab')
      return
    }

    const allTabRow = document.querySelector(`#nav-0 tr[data-row-unique-id="${rowUniqueId}"]`)
    if (!allTabRow) {
      Logger.warn(`ALL tab row not found for unique ID: ${rowUniqueId}`)
      return
    }

    allTabRow.dataset.planProductPriceValue = this.priceValue
    allTabRow.dataset.planProductCategoryIdValue = this.categoryIdValue

    Logger.log(`ALL tab row updated: price=${this.priceValue}, categoryId=${this.categoryIdValue}`)

    const allTabRowController = this.application.getControllerForElementAndIdentifier(
      allTabRow,
      'resources--plan-product--row'
    )

    if (allTabRowController && allTabRowController !== this) {
      allTabRowController.priceValue = this.priceValue
      allTabRowController.categoryIdValue = this.categoryIdValue

      if (typeof allTabRowController.updatePriceDisplay === 'function') {
        allTabRowController.updatePriceDisplay()
      }

      if (allTabRowController.hasProductionCountTarget) {
        allTabRowController.productionCountTarget.disabled = false
        Logger.log('ALL tab production count input force enabled')
      }

      if (typeof allTabRowController.calculate === 'function') {
        allTabRowController.calculate()
      }

      Logger.log('ALL tab row controller updated and recalculated')
    } else {
      Logger.warn('ALL tab row controller not found or is same instance')
    }
  }

  // ============================================================
  // 外部からのアクセス用
  // ============================================================

  getCurrentValues() {
    const quantity = this.getQuantity()
    const price = this.priceValue || DEFAULT_VALUE.ZERO
    const subtotal = quantity * price

    let effectiveCategoryId = DEFAULT_VALUE.ZERO

    if (this.element.dataset.originalCategoryId) {
      effectiveCategoryId = parseInt(this.element.dataset.originalCategoryId, 10)
    } else if (this.categoryIdValue) {
      effectiveCategoryId = this.categoryIdValue
    } else if (this.element.dataset.planProductCategoryIdValue) {
      effectiveCategoryId = parseInt(this.element.dataset.planProductCategoryIdValue, 10)
    }

    return {
      quantity: quantity,
      price: price,
      subtotal: subtotal,
      categoryId: effectiveCategoryId || DEFAULT_VALUE.ZERO
    }
  }

  // ============================================================
  // 同一タブ内で選択済み商品を無効化
  // ============================================================

  disableSelectedProductsInSameTab() {
    const currentCategoryId = this.element.dataset.categoryId
    if (!currentCategoryId || currentCategoryId === '0') {
      Logger.log(LOG_MESSAGES.SKIPPING_PRODUCT_DISABLE)
      return
    }

    const tbody = this.element.closest('tbody[data-category-id]')
    if (!tbody) {
      Logger.warn(LOG_MESSAGES.TBODY_NOT_FOUND)
      return
    }

    const rows = tbody.querySelectorAll('tr[data-controller*="resources--plan-product--row"]')

    const selectedProductIds = []
    rows.forEach(row => {
      const select = row.querySelector('select[data-resources--plan-product--row-target="productSelect"]')
      if (select && select.value) {
        selectedProductIds.push(select.value)
      }
    })

    Logger.log(LOG_MESSAGES.SELECTED_PRODUCT_IDS(currentCategoryId, selectedProductIds))

    rows.forEach(row => {
      const select = row.querySelector('select[data-resources--plan-product--row-target="productSelect"]')
      if (!select) return

      const currentValue = select.value

      Array.from(select.options).forEach(option => {
        if (option.value && option.value !== currentValue && selectedProductIds.includes(option.value)) {
          option.disabled = true
          Logger.log(LOG_MESSAGES.PRODUCT_DISABLED(option.value))
        } else if (option.value && !selectedProductIds.includes(option.value)) {
          option.disabled = false
        }
      })
    })

    Logger.log(LOG_MESSAGES.PRODUCT_DISABLE_COMPLETED)
  }
}
