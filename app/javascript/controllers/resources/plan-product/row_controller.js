// app/javascript/controllers/resources/plan-product/row_controller.js

import { Controller } from "@hotwired/stimulus"
// 💡 修正: 相対パスをImportmapのピン名（utils/logger）に変更
import Logger from "utils/logger"
// 💡 修正: 相対パスをImportmapのピン名（utils/currency_formatter）に変更
import CurrencyFormatter from "utils/currency_formatter"
/**
 * 製造計画：商品行の計算コントローラー（子）
 * 各行の小計計算を担当
 */
export default class extends Controller {
  static targets = ["productSelect", "productionCount", "priceDisplay", "subtotal"]

  static values = {
    price: Number,
    categoryId: Number
  }

  // ============================================================
  // 初期化
  // ============================================================

  connect() {
    Logger.log('🔌 Plan product row controller connected')

    // 計算中フラグの初期化
    this.isCalculating = false

    // 初期計算
    setTimeout(() => this.calculate(), 100)
  }

  // ============================================================
  // 商品選択時の処理
  // ============================================================

  /**
   * 商品選択時に価格とカテゴリを取得
   * @param {Event} event - change イベント
   */
  async updateProduct(event) {
    const productId = event.target.value
    Logger.log(`📦 Product selected: ${productId}`)

    if (!productId) {
      this.resetProduct()
      return
    }

    await this.fetchProductInfo(productId)
  }

  /**
   * 商品情報をAPIから取得
   * @param {string} productId - 商品ID
   */
  async fetchProductInfo(productId) {
    try {
      const response = await fetch(`/api/v1/products/${productId}/details_for_plan`)
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`)

      const product = await response.json()

      this.priceValue = product.price || 0
      this.categoryIdValue = product.category_id || 0

      this.updatePriceDisplay()
      this.calculate()
    } catch (error) {
      Logger.error('❌ Product fetch error:', error)
      this.resetProduct()
    }
  }

  /**
   * 価格表示を更新
   */
  updatePriceDisplay() {
    if (this.hasPriceDisplayTarget) {
      this.priceDisplayTarget.textContent = CurrencyFormatter.format(this.priceValue)
      Logger.log(`💰 Price: ${CurrencyFormatter.format(this.priceValue)}`)
    }
  }

  /**
   * 商品情報をリセット
   */
  resetProduct() {
    this.priceValue = 0
    this.categoryIdValue = 0
    this.updatePriceDisplay()
    this.calculate()
  }

  // ============================================================
  // 小計計算
  // ============================================================

  /**
   * 小計を計算
   */
  calculate() {
    // 計算中なら無視
    if (this.isCalculating) return

    this.isCalculating = true
    Logger.log('🧮 Calculate')

    const quantity = this.getQuantity()
    const price = this.priceValue || 0
    const subtotal = quantity * price

    Logger.log(`  ${quantity} × ${price} = ${subtotal}`)

    this.updateSubtotal(subtotal)

    // 親への通知は遅延させて1回だけ
    clearTimeout(this.notifyTimeout)
    this.notifyTimeout = setTimeout(() => {
      this.notifyParent()
      this.isCalculating = false
    }, 100)
  }

  /**
   * 数量を取得
   * @returns {number} - 数量
   */
  getQuantity() {
    if (!this.hasProductionCountTarget) return 0
    return parseFloat(this.productionCountTarget.value) || 0
  }

  /**
   * 小計を更新
   * @param {number} subtotal - 小計
   */
  updateSubtotal(subtotal) {
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(subtotal)
    }
  }

  /**
   * 親コントローラーに再計算を通知
   */
  notifyParent() {
    Logger.log('📢 Notify parent')

    // イベントを dispatch
    this.dispatch('calculated', {
      prefix: 'resources--plan-product--row',
      bubbles: true
    })

    // 直接親コントローラーを探して呼び出す（より確実）
    const parentElement = document.querySelector('[data-resources--plan-product--totals-target="totalContainer"]')
    if (parentElement) {
      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        'resources--plan-product--totals'
      )
      if (parentController && parentController !== this && typeof parentController.recalculate === 'function') {
        Logger.log('📢 Directly calling parent recalculate')
        parentController.recalculate({ type: 'direct-call' })
      } else {
        Logger.warn('⚠️ Parent controller not found or is same as this')
      }
    } else {
      Logger.warn('⚠️ Parent element not found')
    }
  }

  // ============================================================
  // 外部からのアクセス用
  // ============================================================

  /**
   * 現在の値を取得（親コントローラーから呼ばれる）
   * @returns {Object} - { quantity, price, subtotal, categoryId }
   */
  getCurrentValues() {
    const quantity = this.getQuantity()
    return {
      quantity: quantity,
      price: this.priceValue || 0,
      subtotal: quantity * (this.priceValue || 0),
      categoryId: this.categoryIdValue || 0
    }
  }
}
