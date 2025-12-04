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
  PARENT_NOTIFICATION: 100
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
  PARENT_ELEMENT_NOT_FOUND: 'Parent element not found'
}

export default class extends Controller {
  static targets = ["productSelect", "productionCount", "priceDisplay", "subtotal"]

  static values = {
    price: Number,
    categoryId: Number
  }

  // ============================================================
  // 初期化
  // ============================================================

  // コントローラー接続時の処理
  // 計算中フラグを初期化し、既存の商品選択がある場合は
  // 商品情報を取得する(編集画面用)
  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)

    // 計算中フラグの初期化
    this.isCalculating = false

    // 既に商品が選択されている場合は情報を取得(編集画面用)
    if (this.hasProductSelectTarget && this.productSelectTarget.value) {
      const productId = this.productSelectTarget.value
      Logger.log(LOG_MESSAGES.PRODUCT_ALREADY_SELECTED(productId))
      this.fetchProductInfo(productId)
    } else {
      // 新規作成時は初期計算
      setTimeout(() => this.calculate(), DELAY_MS.INITIAL_CALCULATION)
    }
  }

  // ============================================================
  // 商品選択時の処理
  // ============================================================

  // 商品選択時に価格とカテゴリーを取得
  async updateProduct(event) {
    const productId = event.target.value
    Logger.log(LOG_MESSAGES.PRODUCT_SELECTED(productId))

    if (!productId) {
      this.resetProduct()
      return
    }

    await this.fetchProductInfo(productId)
  }

  // 商品情報をAPIから取得
  // /api/v1/products/:id/fetch_plan_details から
  // 商品の価格とカテゴリーIDを取得し、表示を更新する
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

  // 価格表示を更新
  updatePriceDisplay() {
    if (this.hasPriceDisplayTarget) {
      this.priceDisplayTarget.textContent = CurrencyFormatter.format(this.priceValue)
      Logger.log(LOG_MESSAGES.PRICE_DISPLAY_UPDATED(CurrencyFormatter.format(this.priceValue)))
    } else {
      Logger.warn(LOG_MESSAGES.PRICE_DISPLAY_TARGET_NOT_FOUND)
    }
  }

  // 商品情報をリセット
  resetProduct() {
    this.priceValue = DEFAULT_VALUE.ZERO
    this.categoryIdValue = DEFAULT_VALUE.ZERO
    this.updatePriceDisplay()

    // 小計もリセット
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(DEFAULT_VALUE.ZERO)
    }

    this.calculate()
    Logger.log(LOG_MESSAGES.PRODUCT_RESET)
  }

  // ============================================================
  // 小計計算
  // ============================================================

  // 小計を計算
  // 数量×単価で小計を計算し、表示を更新
  // 親コントローラーへの通知を遅延実行する
  calculate() {
    // 計算中なら無視
    if (this.isCalculating) return

    this.isCalculating = true
    Logger.log(LOG_MESSAGES.CALCULATE_STARTED)

    const quantity = this.getQuantity()
    const price = this.priceValue || DEFAULT_VALUE.ZERO
    const subtotal = quantity * price

    Logger.log(LOG_MESSAGES.CALCULATION(quantity, price, subtotal))

    this.updateSubtotal(subtotal)

    // 親への通知は遅延させて1回だけ
    clearTimeout(this.notifyTimeout)
    this.notifyTimeout = setTimeout(() => {
      this.notifyParent()
      this.isCalculating = false
    }, DELAY_MS.PARENT_NOTIFICATION)
  }

  // 数量を取得
  getQuantity() {
    if (!this.hasProductionCountTarget) return DEFAULT_VALUE.ZERO
    const value = parseFloat(this.productionCountTarget.value) || DEFAULT_VALUE.ZERO
    Logger.log(LOG_MESSAGES.QUANTITY(value))
    return value
  }

  // 小計を更新
  updateSubtotal(subtotal) {
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(subtotal)
      Logger.log(LOG_MESSAGES.SUBTOTAL_UPDATED(CurrencyFormatter.format(subtotal)))
    } else {
      Logger.warn(LOG_MESSAGES.SUBTOTAL_TARGET_NOT_FOUND)
    }
  }

  // 親コントローラーに再計算を通知
  // resources--plan-product--totals コントローラーの
  // recalculate メソッドを直接呼び出す
  notifyParent() {
    Logger.log(LOG_MESSAGES.NOTIFYING_PARENT)

    // 直接親コントローラーを探して呼び出す
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

  // ALLタブの対応行に価格とカテゴリーIDを同期
  // カテゴリータブで商品選択後、全てタブの同じ行を更新する
  syncPriceToAllTab() {
    const rowUniqueId = this.element.dataset.rowUniqueId
    if (!rowUniqueId) {
      Logger.warn('Row unique ID not found, cannot sync to ALL tab')
      return
    }

    // 全てタブ(#nav-0)の対応行を検索
    const allTabRow = document.querySelector(`#nav-0 tr[data-row-unique-id="${rowUniqueId}"]`)
    if (!allTabRow) {
      Logger.warn(`ALL tab row not found for unique ID: ${rowUniqueId}`)
      return
    }

    // data属性を更新
    allTabRow.dataset.planProductPriceValue = this.priceValue
    allTabRow.dataset.planProductCategoryIdValue = this.categoryIdValue

    Logger.log(`ALLタブの行を更新: price=${this.priceValue}, categoryId=${this.categoryIdValue}`)

    // 全てタブの行コントローラーを取得して再計算
    const allTabRowController = this.application.getControllerForElementAndIdentifier(
      allTabRow,
      'resources--plan-product--row'
    )

    if (allTabRowController && allTabRowController !== this) {
      // 価格とカテゴリーIDを直接設定
      allTabRowController.priceValue = this.priceValue
      allTabRowController.categoryIdValue = this.categoryIdValue

      // 表示を更新
      if (typeof allTabRowController.updatePriceDisplay === 'function') {
        allTabRowController.updatePriceDisplay()
      }

      // 小計を再計算
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

  // 現在の値を取得(親コントローラーから呼ばれる)
  // 親コントローラーが合計計算時に各行の値を取得するために使用
  getCurrentValues() {
    const quantity = this.getQuantity()
    const price = this.priceValue || DEFAULT_VALUE.ZERO
    const subtotal = quantity * price

    // ALLタブの場合は data-original-category-id を使用、それ以外は categoryIdValue を使用
    const originalCategoryId = this.element.dataset.originalCategoryId
    const effectiveCategoryId = originalCategoryId || this.categoryIdValue || DEFAULT_VALUE.ZERO

    return {
      quantity: quantity,
      price: price,
      subtotal: subtotal,
      categoryId: parseInt(effectiveCategoryId, 10) || DEFAULT_VALUE.ZERO
    }
  }
}
