// app/javascript/controllers/resources/plan-product/totals_controller.js
import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"
import CurrencyFormatter from "utils/currency_formatter"
/**
 * 製造計画：総合計・カテゴリ合計の管理コントローラー（親）
 */
export default class extends Controller {
  static targets = ["grandTotal", "categoryTotal", "totalContainer"]

  // ============================================================
  // 初期化
  // ============================================================

  connect() {
    Logger.log('👨 Plan product totals controller connected (parent mode)')

    // 計算中フラグの初期化
    this.isUpdatingTotals = false

    // 初期計算
    this.updateTotals()
  }

  // ============================================================
  // 合計更新
  // ============================================================

  /**
   * 再計算を実行（子コントローラーから呼ばれる）
   * @param {Event} event - カスタムイベント
   */
  recalculate(event) {
    // 既に更新中なら無視
    if (this.isUpdatingTotals) {
      Logger.log('⏭️ Already updating totals, skipping')
      return
    }

    Logger.log(`🔄 Recalculate triggered: ${event?.type}`)

    // 短い遅延で実行（連続呼び出しを防ぐ）
    clearTimeout(this.updateTimeout)
    this.updateTimeout = setTimeout(() => this.updateTotals(), 50)
  }

  /**
   * 総合計とカテゴリ合計を更新
   */
  updateTotals() {
    // 更新中フラグを立てる
    if (this.isUpdatingTotals) return
    this.isUpdatingTotals = true

    Logger.log('📊 Updating totals')

    const allTabPane = document.querySelector('#nav-0')
    if (!allTabPane) {
      Logger.warn('⚠️ ALL tab not found')
      this.isUpdatingTotals = false
      return
    }

    let grandTotal = 0
    let categoryTotals = {}

    const productRows = allTabPane.querySelectorAll('tr[data-controller~="resources--plan-product--row"]')
    Logger.log(`📊 Scanning ${productRows.length} rows`)

    productRows.forEach((row, index) => {
      // テンプレート行はスキップ
      if (row.outerHTML.includes('NEW_RECORD')) return

      // 削除済み行はスキップ
      const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
      if (destroyInput?.value === '1') return

      // 非表示行はスキップ
      if (row.style.display === 'none') return

      const childController = this.application.getControllerForElementAndIdentifier(
        row,
        'resources--plan-product--row'
      )

      if (childController?.getCurrentValues) {
        const values = childController.getCurrentValues()
        Logger.log(
          `  Row ${index}: ${values.quantity} × ${values.price} = ${values.subtotal} (cat: ${values.categoryId})`
        )

        grandTotal += values.subtotal

        if (values.categoryId && values.categoryId !== 0 && values.subtotal > 0) {
          categoryTotals[values.categoryId] = (categoryTotals[values.categoryId] || 0) + values.subtotal
        }
      }
    })

    Logger.log(`💰 Grand total: ${grandTotal}`)
    Logger.log(`📊 Category totals:`, categoryTotals)

    this.updateDisplay(grandTotal, categoryTotals)

    // フラグを解除
    this.isUpdatingTotals = false
  }

  /**
   * 表示を更新
   * @param {number} grandTotal - 総合計
   * @param {Object} categoryTotals - カテゴリ別合計
   */
  updateDisplay(grandTotal, categoryTotals) {
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = CurrencyFormatter.format(grandTotal)
      Logger.log(`✅ Grand total updated: ${CurrencyFormatter.format(grandTotal)}`)
    }

    if (this.hasCategoryTotalTarget) {
      this.categoryTotalTargets.forEach(target => {
        const categoryId = target.dataset.categoryId
        const total = categoryTotals[categoryId] || 0
        target.textContent = CurrencyFormatter.format(total)
        Logger.log(`✅ Category ${categoryId} updated: ${CurrencyFormatter.format(total)}`)
      })
    }
  }
}
