/**
 * @file resources/plan-product/row_controller.js
 * 製造計画の商品行における小計計算コントローラー（子）
 *
 * @module Controllers/Resources/PlanProduct
 */

import { Controller } from "@hotwired/stimulus"
import Logger from "../../../utils/logger"
import CurrencyFormatter from "../../../utils/currency_formatter"

/**
 * Plan Product Row Controller (Child)
 *
 * 製造計画：商品行の計算コントローラー（子）。
 * 各行の小計計算を担当する。
 *
 * 責務:
 * - 商品選択時のAPI連携（価格・カテゴリ取得）
 * - 数量×単価の小計計算
 * - 親コントローラーへの再計算通知
 * - 編集時の既存データ読み込み
 *
 * データフロー:
 * 1. 商品選択 → updateProduct() → API取得 → 価格・カテゴリ設定
 * 2. 数量入力 → calculate() → 小計計算 → 親に通知
 * 3. 親コントローラー → getCurrentValues() → 値取得 → 合計計算
 *
 * @extends Controller
 *
 * @example HTML での使用
 *   <tr data-controller="resources--plan-product--row" data-resources--plan-product--row-price-value="1000">
 *     <select data-resources--plan-product--row-target="productSelect" data-action="change->resources--plan-product--row#updateProduct">
 *       <option value="">選択</option>
 *     </select>
 *     <input type="number" data-resources--plan-product--row-target="productionCount" data-action="input->resources--plan-product--row#calculate" />
 *     <span data-resources--plan-product--row-target="priceDisplay">¥1,000</span>
 *     <span data-resources--plan-product--row-target="subtotal">¥0</span>
 *   </tr>
 */
export default class extends Controller {
  static targets = ["productSelect", "productionCount", "priceDisplay", "subtotal"]

  static values = {
    price: Number,
    categoryId: Number
  }

  /**
   * 遅延時間定数: 初期計算処理の遅延（ミリ秒）
   *
   * コントローラー接続直後の初期計算を遅延させる時間。
   * DOM構築完了後に確実に計算が実行されるよう、わずかな待機時間を設ける。
   */
  static INITIAL_CALCULATION_DELAY_MS = 100

  /**
   * 遅延時間定数: 親への通知処理の遅延（ミリ秒）
   *
   * 小計計算後、親コントローラーへの通知を遅延させる時間。
   * 短時間に複数の変更が発生した場合、最後の変更から指定時間後に
   * 通知を実行することで、不要な中間通知を防ぐ。
   */
  static PARENT_NOTIFICATION_DELAY_MS = 100

  // ============================================================
  // 初期化
  // ============================================================

  /**
   * コントローラー接続時の処理
   *
   * 計算中フラグを初期化し、既存の商品選択がある場合は
   * 商品情報を取得する（編集画面用）。
   */
  connect() {
    Logger.log('Plan product row controller connected')

    // 計算中フラグの初期化
    this.isCalculating = false

    // 既に商品が選択されている場合は情報を取得（編集画面用）
    if (this.hasProductSelectTarget && this.productSelectTarget.value) {
      const productId = this.productSelectTarget.value
      Logger.log(`Product already selected on connect: ${productId}`)
      this.fetchProductInfo(productId)
    } else {
      // 新規作成時は初期計算
      setTimeout(() => this.calculate(), this.constructor.INITIAL_CALCULATION_DELAY_MS)
    }
  }

  // ============================================================
  // 商品選択時の処理
  // ============================================================

  /**
   * 商品選択時に価格とカテゴリを取得
   *
   * @param {Event} event - change イベント
   * @async
   */
  async updateProduct(event) {
    const productId = event.target.value
    Logger.log(`Product selected: ${productId}`)

    if (!productId) {
      this.resetProduct()
      return
    }

    await this.fetchProductInfo(productId)
  }

  /**
   * 商品情報をAPIから取得
   *
   * @param {string} productId - 商品ID
   * @async
   *
   * /api/v1/products/:id/fetch_plan_details から
   * 商品の価格とカテゴリIDを取得し、表示を更新する。
   */
  async fetchProductInfo(productId) {
    try {
      Logger.log(`Fetching product info for: ${productId}`)

      const response = await fetch(`/api/v1/products/${productId}/fetch_plan_details`)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const product = await response.json()
      Logger.log('Product data received:', product)

      this.priceValue = product.price || 0
      this.categoryIdValue = product.category_id || 0

      this.updatePriceDisplay()
      this.calculate()

      Logger.log(`Price set to: ${this.priceValue}, Category: ${this.categoryIdValue}`)
    } catch (error) {
      Logger.error('Product fetch error:', error)
      alert('商品情報の取得に失敗しました。ページを再読み込みしてください。')
      this.resetProduct()
    }
  }

  /**
   * 価格表示を更新
   */
  updatePriceDisplay() {
    if (this.hasPriceDisplayTarget) {
      this.priceDisplayTarget.textContent = CurrencyFormatter.format(this.priceValue)
      Logger.log(`Price display updated: ${CurrencyFormatter.format(this.priceValue)}`)
    } else {
      Logger.warn('Price display target not found')
    }
  }

  /**
   * 商品情報をリセット
   */
  resetProduct() {
    this.priceValue = 0
    this.categoryIdValue = 0
    this.updatePriceDisplay()

    // 小計もリセット
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(0)
    }

    this.calculate()
    Logger.log('Product reset')
  }

  // ============================================================
  // 小計計算
  // ============================================================

  /**
   * 小計を計算
   *
   * 数量×単価で小計を計算し、表示を更新。
   * 親コントローラーへの通知を遅延実行する。
   */
  calculate() {
    // 計算中なら無視
    if (this.isCalculating) return

    this.isCalculating = true
    Logger.log('Calculate started')

    const quantity = this.getQuantity()
    const price = this.priceValue || 0
    const subtotal = quantity * price

    Logger.log(`${quantity} × ${price} = ${subtotal}`)

    this.updateSubtotal(subtotal)

    // 親への通知は遅延させて1回だけ
    clearTimeout(this.notifyTimeout)
    this.notifyTimeout = setTimeout(() => {
      this.notifyParent()
      this.isCalculating = false
    }, this.constructor.PARENT_NOTIFICATION_DELAY_MS)
  }

  /**
   * 数量を取得
   *
   * @return {number} 数量
   */
  getQuantity() {
    if (!this.hasProductionCountTarget) return 0
    const value = parseFloat(this.productionCountTarget.value) || 0
    Logger.log(`Quantity: ${value}`)
    return value
  }

  /**
   * 小計を更新
   *
   * @param {number} subtotal - 小計
   */
  updateSubtotal(subtotal) {
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(subtotal)
      Logger.log(`Subtotal updated: ${CurrencyFormatter.format(subtotal)}`)
    } else {
      Logger.warn('Subtotal target not found')
    }
  }

  /**
   * 親コントローラーに再計算を通知
   *
   * resources--plan-product--totals コントローラーの
   * recalculate メソッドを直接呼び出す。
   */
  notifyParent() {
    Logger.log('Notifying parent to recalculate')

    // 直接親コントローラーを探して呼び出す
    const parentElement = document.querySelector('[data-controller~="resources--plan-product--totals"]')
    if (parentElement) {
      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        'resources--plan-product--totals'
      )
      if (parentController && parentController !== this && typeof parentController.recalculate === 'function') {
        Logger.log('Calling parent recalculate')
        parentController.recalculate({ type: 'row-calculated' })
      } else {
        Logger.warn('Parent controller not found or invalid')
      }
    } else {
      Logger.warn('Parent element not found')
    }
  }

  // ============================================================
  // 外部からのアクセス用
  // ============================================================

  /**
   * 現在の値を取得（親コントローラーから呼ばれる）
   *
   * @return {Object} { quantity, price, subtotal, categoryId }
   *
   * 親コントローラーが合計計算時に各行の値を取得するために使用。
   */
  getCurrentValues() {
    const quantity = this.getQuantity()
    const price = this.priceValue || 0
    const subtotal = quantity * price

    return {
      quantity: quantity,
      price: price,
      subtotal: subtotal,
      categoryId: this.categoryIdValue || 0
    }
  }
}
