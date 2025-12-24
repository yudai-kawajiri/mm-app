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
// - フォーム送信時の空行自動削除
//
// データフロー:
// 1. 商品選択 → updateProduct() → API取得 → 価格・カテゴリー設定
// 2. 数量入力 → calculate() → 小計計算 → 親に通知
// 3. 親コントローラー → getCurrentValues() → 値取得 → 合計計算
// 4. フォーム送信 → markForDestructionIfEmpty() → _destroy フラグ設定
//
// Targets:
// - productSelect: 商品選択セレクトボックス
// - productIdHidden: 商品ID hidden フィールド(全てタブ用)
// - productNameDisplay: 商品名表示要素(全てタブ用)
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
  PRODUCT_DETAILS: (productId) => {
    // URLから company_slug を取得: /c/ok2eke/... → "ok2eke"
    const companySlug = window.location.pathname.split('/')[2]
    return `/c/${companySlug}/api/v1/products/${productId}/fetch_plan_details`
  }
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

    // フォーム送信前に空行をチェック
    this.setupFormSubmitListener()

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
        this.enableProductionCount()
        Logger.log('Production count input enabled after delay')
      }, DELAY_MS.ENABLE_INPUT_DELAY)
      this.fetchProductInfo(productId)
    } else {
      Logger.log(LOG_MESSAGES.NO_PRODUCT_SELECTED)
      this.disableProductionCount()
      setTimeout(() => this.calculate(), DELAY_MS.INITIAL_CALCULATION)
    }

    setTimeout(() => {
      this.disableSelectedProductsInSameTab()
    }, 200)
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

    this.disableSelectedProductsInSameTab()
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

      // 数量フィールドを有効化
      this.enableProductionCount()

      this.calculate()

      this.syncPriceToAllTab()

      Logger.log(LOG_MESSAGES.PRICE_SET(this.priceValue, this.categoryIdValue))
    } catch (error) {
      Logger.error(LOG_MESSAGES.PRODUCT_FETCH_ERROR, error)
      console.error(i18n.t(I18N_KEYS.PRODUCT_FETCH_FAILED), error)
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

    // 数量フィールドを先に無効化(number-inputコントローラーの干渉を防ぐ)
    this.disableProductionCount()

    // 数量もリセット
    if (this.hasProductionCountTarget) {
      this.productionCountTarget.value = DEFAULT_VALUE.EMPTY_STRING
    } else {
      console.warn('[resetProduct] productionCountTarget not found!')
    }

    // 小計もリセット
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(DEFAULT_VALUE.ZERO)
    }

    // 「全て」タブの数量と売価もリセット
    this.resetAllTabProductionCount()

    // 親に通知して合計を更新
    this.notifyParent()

    Logger.log(LOG_MESSAGES.PRODUCT_RESET)
  }

  // 数量入力フィールドを無効化
  disableProductionCount() {
    if (this.hasProductionCountTarget) {
      this.productionCountTarget.disabled = true
      Logger.log('Production count input disabled')
    }
  }

  // 数量入力フィールドを有効化
  enableProductionCount() {
    if (this.hasProductionCountTarget) {
      this.productionCountTarget.disabled = false
      Logger.log('Production count input enabled')
    }
  }

  // ============================================================
  // 入力フィールドの有効化/無効化(後方互換性)
  // ============================================================

  enableInputFields() {
    this.enableProductionCount()
  }

  disableInputFields() {
    this.disableProductionCount()
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

  // 親コントローラーに通知
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

  // 「全て」タブの数量と売価をリセット
  resetAllTabProductionCount() {
    const rowUniqueId = this.element.dataset.rowUniqueId
    if (!rowUniqueId) {
      Logger.warn('Row unique ID not found, cannot reset ALL tab production count')
      return
    }

    // 全てタブ(#nav-0)の対応行を検索
    const allTabRow = document.querySelector(`#nav-0 tr[data-row-unique-id="${rowUniqueId}"]`)
    if (!allTabRow) {
      Logger.warn(`ALL tab row not found for unique ID: ${rowUniqueId}`)
      return
    }

    Logger.log(`Resetting ALL tab production count for unique ID: ${rowUniqueId}`)

    // 全てタブの行コントローラーを取得
    const allTabRowController = this.application.getControllerForElementAndIdentifier(
      allTabRow,
      'resources--plan-product--row'
    )

    if (allTabRowController && allTabRowController !== this) {
      // 価格をリセット
      allTabRowController.priceValue = DEFAULT_VALUE.ZERO
      allTabRowController.categoryIdValue = DEFAULT_VALUE.ZERO

      // 価格表示を更新
      if (typeof allTabRowController.updatePriceDisplay === 'function') {
        allTabRowController.updatePriceDisplay()
      }

      // 数量フィールドを無効化
      if (typeof allTabRowController.disableProductionCount === 'function') {
        allTabRowController.disableProductionCount()
      }

      // 数量をリセット
      if (allTabRowController.hasProductionCountTarget) {
        allTabRowController.productionCountTarget.value = DEFAULT_VALUE.EMPTY_STRING
      }

      // 小計をリセット
      if (allTabRowController.hasSubtotalTarget) {
        allTabRowController.subtotalTarget.textContent = CurrencyFormatter.format(DEFAULT_VALUE.ZERO)
      }

      Logger.log('ALL tab production count and price reset completed')
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
      // 非表示または削除マーク付きの行はスキップ
      const rowStyle = window.getComputedStyle(row)
      const destroyInput = row.querySelector('input[name*="[_destroy]"]')
      if (rowStyle.display === 'none' || (destroyInput && destroyInput.value === '1')) {
        return
      }

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

  // ============================================================
  // フォーム送信前処理
  // ============================================================

  // フォーム送信前に空行を自動削除する処理を設定
  setupFormSubmitListener() {
    const form = this.element.closest('form')
    if (!form) {
      Logger.warn('Form not found for row controller')
      return
    }

    // 既にリスナーが設定されている場合はスキップ
    if (form.dataset.rowSubmitListenerAdded) {
      return
    }

    form.addEventListener('submit', (event) => {
      this.markForDestructionIfEmpty()
    })

    form.dataset.rowSubmitListenerAdded = 'true'
    Logger.log('Form submit listener added')
  }

  // 商品が選択されていない場合、この行を削除対象としてマーク
  markForDestructionIfEmpty() {
    let productId = null

    // 商品IDを取得(select フィールドから)
    if (this.hasProductSelectTarget && this.productSelectTarget.value) {
      productId = this.productSelectTarget.value
    }

    // 商品が選択されていない場合
    if (!productId) {
      // ★修正: 既存レコード(idがある行)はスキップ
      const idInput = this.element.querySelector('input[name*="[id]"]')
      if (idInput && idInput.value) {
        Logger.log('Existing record detected, skipping destruction')
        return
      }

      Logger.log('Empty row detected, marking for destruction')

      // _destroy フィールドを探す
      let destroyInput = this.element.querySelector('input[name*="[_destroy]"]')

      // _destroy フィールドが存在しない場合は作成
      if (!destroyInput) {
        destroyInput = document.createElement('input')
        destroyInput.type = 'hidden'
        destroyInput.name = this.getDestroyFieldName()
        destroyInput.value = '1'
        this.element.appendChild(destroyInput)
        Logger.log('_destroy field created and set to 1')
      } else {
        // 既存の _destroy フィールドに 1 を設定
        destroyInput.value = '1'
        Logger.log('_destroy field updated to 1')
      }
    }
  }
  // _destroy フィールドの name 属性を生成
  // 例: plan[plan_products_attributes][0][product_id] → plan[plan_products_attributes][0][_destroy]
  getDestroyFieldName() {
    if (this.hasProductSelectTarget && this.productSelectTarget.name) {
      // [product_id] を [_destroy] に置換
      return this.productSelectTarget.name.replace(/\[product_id\]$/, '[_destroy]')
    }

    Logger.warn('Could not determine destroy field name')
    return ''
  }
}
