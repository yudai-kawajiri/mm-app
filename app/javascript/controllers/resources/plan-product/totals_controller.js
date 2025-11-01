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

    // 初期計算（遅延させて確実に実行）
    setTimeout(() => this.updateTotals(), 200)
  }

  // ============================================================
  // 合計更新
  // ============================================================

  /**
   * 再計算を実行（子コントローラーやタブコントローラーから呼ばれる）
   * @param {Event} event - カスタムイベント
   */
  recalculate(event) {
    Logger.log(`🔄 Recalculate triggered: ${event?.type}`)

    // 短い遅延で実行（連続呼び出しを防ぐ）
    clearTimeout(this.updateTimeout)
    this.updateTimeout = setTimeout(() => this.updateTotals(), 100)
  }

  /**
   * 総合計とカテゴリ合計を更新
   */
  updateTotals() {
    // 既に更新中なら無視
    if (this.isUpdatingTotals) {
      Logger.log('⏭️ Already updating totals, skipping')
      return
    }

    this.isUpdatingTotals = true
    Logger.log('📊 ============ Starting totals update ============')

    const allTabPane = document.querySelector('#nav-0')
    if (!allTabPane) {
      Logger.warn('⚠️ ALL tab not found')
      this.isUpdatingTotals = false
      return
    }

    let grandTotal = 0
    let categoryTotals = {}
    let rowCount = 0

    const productRows = allTabPane.querySelectorAll('tr[data-controller~="resources--plan-product--row"]')
    Logger.log(`📊 Scanning ${productRows.length} rows in ALL tab`)

    productRows.forEach((row, index) => {
      // テンプレート行はスキップ
      if (row.outerHTML.includes('NEW_RECORD')) {
        Logger.log(`  Row ${index}: Skipped (template)`)
        return
      }

      // 削除済み行はスキップ
      const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
      if (destroyInput && destroyInput.value === '1') {
        Logger.log(`  Row ${index}: Skipped (marked for destruction)`)
        return
      }

      // 非表示行はスキップ
      if (row.style.display === 'none') {
        Logger.log(`  Row ${index}: Skipped (hidden)`)
        return
      }

      const childController = this.application.getControllerForElementAndIdentifier(
        row,
        'resources--plan-product--row'
      )

      if (childController && typeof childController.getCurrentValues === 'function') {
        const values = childController.getCurrentValues()

        Logger.log(
          `  Row ${index}: quantity=${values.quantity}, price=${values.price}, subtotal=${values.subtotal}, category=${values.categoryId}`
        )

        // 小計が0より大きい場合のみ集計
        if (values.subtotal > 0) {
          grandTotal += values.subtotal
          rowCount++

          // カテゴリ別集計（カテゴリIDが有効な場合）
          if (values.categoryId && values.categoryId !== 0) {
            if (!categoryTotals[values.categoryId]) {
              categoryTotals[values.categoryId] = 0
            }
            categoryTotals[values.categoryId] += values.subtotal
          }
        }
      } else {
        Logger.warn(`  Row ${index}: Controller not found or invalid`)
      }
    })

    Logger.log(`💰 Grand total: ${CurrencyFormatter.format(grandTotal)} (from ${rowCount} rows)`)
    Logger.log(`📊 Category totals:`, categoryTotals)

    this.updateDisplay(grandTotal, categoryTotals)

    Logger.log('📊 ============ Totals update complete ============')

    // フラグを解除
    this.isUpdatingTotals = false
  }

  /**
   * 表示を更新
   * @param {number} grandTotal - 総合計
   * @param {Object} categoryTotals - カテゴリ別合計
   */
  updateDisplay(grandTotal, categoryTotals) {
    // 総合計の更新
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = CurrencyFormatter.format(grandTotal)
      Logger.log(`✅ Grand total display updated: ${CurrencyFormatter.format(grandTotal)}`)
    } else {
      Logger.warn('⚠️ Grand total target not found')
    }

    // カテゴリ別合計の更新
    if (this.hasCategoryTotalTarget) {
      this.categoryTotalTargets.forEach(target => {
        const categoryId = target.dataset.categoryId
        const total = categoryTotals[categoryId] || 0
        target.textContent = CurrencyFormatter.format(total)
        Logger.log(`✅ Category ${categoryId} total updated: ${CurrencyFormatter.format(total)}`)
      })
    }
  }
}