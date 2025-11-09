/**
 * @file resources/plan-product/totals_controller.js
 * 製造計画の商品行における総合計・カテゴリ別合計管理コントローラー
 *
 * @module Controllers/Resources/PlanProduct
 */

import { Controller } from "@hotwired/stimulus"
import Logger from "../../../utils/logger"
import CurrencyFormatter from "../../../utils/currency_formatter"

/**
 * Plan-Product Totals Controller
 *
 * 製造計画の商品行の総合計・カテゴリ別合計を管理する親コントローラー。
 * 各カテゴリタブ配下の商品行から小計を収集し、全体の合計金額を計算・表示する。
 *
 * 責務:
 * - 全商品行の総合計金額計算
 * - カテゴリ別合計金額計算
 * - 合計表示要素の更新
 * - 子コントローラー（商品行・タブ）からの再計算イベント処理
 *
 * データフロー:
 * 1. 商品行の数量・原価が変更される
 * 2. row_controller が小計を計算し、親（このコントローラー）に通知
 * 3. recalculate() が全行を再集計
 * 4. 合計表示要素を更新
 *
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["grandTotal", "categoryTotal", "totalContainer"]

  /**
   * 遅延時間定数: 再計算処理の遅延（ミリ秒）
   *
   * 短時間に複数の変更が発生した場合、最後の変更から指定時間後に
   * 再計算を実行することで、不要な中間計算を防ぐ。
   */
  static RECALCULATION_DELAY_MS = 100

  /**
   * 遅延時間定数: 初期計算処理の遅延（ミリ秒）
   *
   * コントローラー接続直後の初期計算を遅延させる時間。
   * DOM構築完了後に確実に計算が実行されるよう、待機時間を設ける。
   */
  static INITIAL_CALCULATION_DELAY_MS = 200

  // ============================================================
  // 初期化
  // ============================================================

  /**
   * コントローラー接続時の初期化処理
   */
  connect() {
    Logger.log('Plan product totals controller connected (parent mode)')

    // 計算中フラグの初期化
    this.isUpdatingTotals = false

    // 初期計算（遅延させて確実に実行）
    setTimeout(() => this.updateTotals(), this.constructor.INITIAL_CALCULATION_DELAY_MS)
  }

  /**
   * コントローラー切断時のクリーンアップ
   */
  disconnect() {
    if (this.updateTimeout) {
      clearTimeout(this.updateTimeout)
    }
  }

  // ============================================================
  // 合計更新
  // ============================================================

  /**
   * 再計算を実行（子コントローラーやタブコントローラーから呼ばれる）
   *
   * @param {Event} event - カスタムイベントオブジェクト（オプション）
   */
  recalculate(event) {
    Logger.log(`Recalculate triggered: ${event?.type}`)

    // 短い遅延で実行（連続呼び出しを防ぐ）
    clearTimeout(this.updateTimeout)
    this.updateTimeout = setTimeout(() => this.updateTotals(), this.constructor.RECALCULATION_DELAY_MS)
  }

  /**
   * 総合計とカテゴリ合計を更新
   *
   * ALLタブ内の全商品行を走査し、子コントローラーから値を取得して集計。
   * カテゴリ別合計と総合計を算出し、対応する表示要素を更新する。
   */
  updateTotals() {
    // 既に更新中なら無視
    if (this.isUpdatingTotals) {
      Logger.log('Already updating totals, skipping')
      return
    }

    this.isUpdatingTotals = true
    Logger.log('============ Starting totals update ============')

    const allTabPane = document.querySelector('#nav-0')
    if (!allTabPane) {
      Logger.warn('ALL tab not found')
      this.isUpdatingTotals = false
      return
    }

    let grandTotal = 0
    let categoryTotals = {}
    let rowCount = 0

    const productRows = allTabPane.querySelectorAll('tr[data-controller~="resources--plan-product--row"]')
    Logger.log(`Scanning ${productRows.length} rows in ALL tab`)

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

    Logger.log(`Grand total: ${CurrencyFormatter.format(grandTotal)} (from ${rowCount} rows)`)
    Logger.log(`Category totals:`, categoryTotals)

    this.updateDisplay(grandTotal, categoryTotals)

    Logger.log('============ Totals update complete ============')

    // フラグを解除
    this.isUpdatingTotals = false
  }

  /**
   * 表示を更新
   *
   * @param {number} grandTotal - 総合計金額
   * @param {Object} categoryTotals - カテゴリIDをキー、合計金額を値とするオブジェクト
   * @private
   */
  updateDisplay(grandTotal, categoryTotals) {
    // 総合計の更新
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = CurrencyFormatter.format(grandTotal)
      Logger.log(`Grand total display updated: ${CurrencyFormatter.format(grandTotal)}`)
    } else {
      Logger.warn('Grand total target not found')
    }

    // カテゴリ別合計の更新
    if (this.hasCategoryTotalTarget) {
      this.categoryTotalTargets.forEach(target => {
        const categoryId = target.dataset.categoryId
        const total = categoryTotals[categoryId] || 0
        target.textContent = CurrencyFormatter.format(total)
        Logger.log(`Category ${categoryId} total updated: ${CurrencyFormatter.format(total)}`)
      })
    }
  }
}
