// app/javascript/controllers/resources/plan-product/row_controller.js

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"
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

    // 既に商品が選択されている場合は情報を取得（編集画面用）
    if (this.hasProductSelectTarget && this.productSelectTarget.value) {
      const productId = this.productSelectTarget.value
      Logger.log(`📦 Product already selected on connect: ${productId}`)
      this.fetchProductInfo(productId)
    } else {
      // 新規作成時は初期計算
      setTimeout(() => this.calculate(), 100)
    }
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
      Logger.log(`🔍 Fetching product info for: ${productId}`)

      const response = await fetch(`/api/v1/products/${productId}/fetch_plan_details`)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const product = await response.json()
      Logger.log('✅ Product data received:', product)

      this.priceValue = product.price || 0
      this.categoryIdValue = product.category_id || 0

      this.updatePriceDisplay()
      this.calculate()

      Logger.log(`✅ Price set to: ${this.priceValue}, Category: ${this.categoryIdValue}`)
    } catch (error) {
      Logger.error('❌ Product fetch error:', error)
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
      Logger.log(`💰 Price display updated: ${CurrencyFormatter.format(this.priceValue)}`)
    } else {
      Logger.warn('⚠️ Price display target not found')
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
    Logger.log('🔄 Product reset')
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
    Logger.log('🧮 Calculate started')

    const quantity = this.getQuantity()
    const price = this.priceValue || 0
    const subtotal = quantity * price

    Logger.log(`  📊 ${quantity} × ${price} = ${subtotal}`)

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
    const value = parseFloat(this.productionCountTarget.value) || 0
    Logger.log(`📦 Quantity: ${value}`)
    return value
  }

  /**
   * 小計を更新
   * @param {number} subtotal - 小計
   */
  updateSubtotal(subtotal) {
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = CurrencyFormatter.format(subtotal)
      Logger.log(`✅ Subtotal updated: ${CurrencyFormatter.format(subtotal)}`)
    } else {
      Logger.warn('⚠️ Subtotal target not found')
    }
  }

  /**
   * 親コントローラーに再計算を通知
   */
  notifyParent() {
    Logger.log('📢 Notifying parent to recalculate')

    // 直接親コントローラーを探して呼び出す
    const parentElement = document.querySelector('[data-controller~="resources--plan-product--totals"]')
    if (parentElement) {
      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        'resources--plan-product--totals'
      )
      if (parentController && parentController !== this && typeof parentController.recalculate === 'function') {
        Logger.log('✅ Calling parent recalculate')
        parentController.recalculate({ type: 'row-calculated' })
      } else {
        Logger.warn('⚠️ Parent controller not found or invalid')
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