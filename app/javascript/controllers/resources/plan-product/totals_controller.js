// Plan Product Totals Controller
//
// 製造計画の商品行の総合計・カテゴリ別合計を管理する親コントローラー
//
// 責務:
// - 全商品行の総合計金額計算
// - カテゴリ別合計金額計算
// - 合計表示要素の更新
// - 子コントローラー（商品行・タブ）からの再計算イベント処理
//
// データフロー:
// 1. 商品行の数量・原価が変更される
// 2. row_controller が小計を計算し、親（このコントローラー）に通知
// 3. recalculate() が全行を再集計
// 4. 合計表示要素を更新
//
// Targets:
// - grandTotal: 総合計表示要素
// - categoryTotal: カテゴリ別合計表示要素
// - totalContainer: 合計コンテナ要素

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

// 定数定義
const DELAY_MS = {
  RECALCULATION: 100,
  INITIAL_CALCULATION: 200
}

const SELECTOR = {
  ALL_TAB_PANE: '#nav-0',
  PRODUCT_ROWS: 'tr[data-controller~="resources--plan-product--row"]',
  DESTROY_INPUT: '[data-form--nested-form-item-target="destroy"]'
}

const CONTROLLER_IDENTIFIER = {
  ROW: 'resources--plan-product--row'
}

const METHOD_NAME = {
  GET_CURRENT_VALUES: 'getCurrentValues'
}

const DATA_ATTRIBUTE = {
  CATEGORY_ID: 'categoryId'
}

const DISPLAY_STYLE = {
  NONE: 'none'
}

const TEMPLATE_MARKER = {
  NEW_RECORD: 'NEW_RECORD'
}

const DESTROY_FLAG = {
  TRUE: '1'
}

const DEFAULT_VALUE = {
  ZERO: 0
}

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'Plan product totals controller connected (parent mode)',
  RECALCULATE_TRIGGERED: (eventType) => `Recalculate triggered: ${eventType}`,
  ALREADY_UPDATING: 'Already updating totals, skipping',
  STARTING_UPDATE: '============ Starting totals update ============',
  ALL_TAB_NOT_FOUND: 'ALL tab not found',
  SCANNING_ROWS: (count) => `Scanning ${count} rows in ALL tab`,
  ROW_SKIPPED_TEMPLATE: (index) => `  Row ${index}: Skipped (template)`,
  ROW_SKIPPED_DESTRUCTION: (index) => `  Row ${index}: Skipped (marked for destruction)`,
  ROW_SKIPPED_HIDDEN: (index) => `  Row ${index}: Skipped (hidden)`,
  ROW_VALUES: (index, quantity, price, subtotal, categoryId) => `  Row ${index}: quantity=${quantity}, price=${price}, subtotal=${subtotal}, category=${categoryId}`,
  ROW_CONTROLLER_NOT_FOUND: (index) => `  Row ${index}: Controller not found or invalid`,
  GRAND_TOTAL: (formattedTotal, count) => `Grand total: ${formattedTotal} (from ${count} rows)`,
  CATEGORY_TOTALS: 'Category totals:',
  UPDATE_COMPLETE: '============ Totals update complete ============',
  GRAND_TOTAL_UPDATED: (formattedTotal) => `Grand total display updated: ${formattedTotal}`,
  GRAND_TOTAL_TARGET_NOT_FOUND: 'Grand total target not found',
  CATEGORY_TOTAL_UPDATED: (categoryId, formattedTotal) => `Category ${categoryId} total updated: ${formattedTotal}`
}

export default class extends Controller {
  static targets = ["grandTotal", "categoryTotal", "totalContainer"]

  // ============================================================
  // 初期化
  // ============================================================

  // コントローラー接続時の初期化処理
  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)

    // 計算中フラグの初期化
    this.isUpdatingTotals = false

    // 初期計算（遅延させて確実に実行）
    setTimeout(() => this.updateTotals(), DELAY_MS.INITIAL_CALCULATION)
  }

  // コントローラー切断時のクリーンアップ
  disconnect() {
    if (this.updateTimeout) {
      clearTimeout(this.updateTimeout)
    }
  }

  // ============================================================
  // 合計更新
  // ============================================================

  // 再計算を実行（子コントローラーやタブコントローラーから呼ばれる）
  recalculate(event) {
    Logger.log(LOG_MESSAGES.RECALCULATE_TRIGGERED(event?.type))

    // 短い遅延で実行（連続呼び出しを防ぐ）
    clearTimeout(this.updateTimeout)
    this.updateTimeout = setTimeout(() => this.updateTotals(), DELAY_MS.RECALCULATION)
  }

  // 総合計とカテゴリ合計を更新
  // ALLタブ内の全商品行を走査し、子コントローラーから値を取得して集計
  // カテゴリ別合計と総合計を算出し、対応する表示要素を更新する
  updateTotals() {
    // 既に更新中なら無視
    if (this.isUpdatingTotals) {
      Logger.log(LOG_MESSAGES.ALREADY_UPDATING)
      return
    }

    this.isUpdatingTotals = true
    Logger.log(LOG_MESSAGES.STARTING_UPDATE)

    const allTabPane = document.querySelector(SELECTOR.ALL_TAB_PANE)
    if (!allTabPane) {
      Logger.warn(LOG_MESSAGES.ALL_TAB_NOT_FOUND)
      this.isUpdatingTotals = false
      return
    }

    let grandTotal = DEFAULT_VALUE.ZERO
    let categoryTotals = {}
    let rowCount = DEFAULT_VALUE.ZERO

    const productRows = allTabPane.querySelectorAll(SELECTOR.PRODUCT_ROWS)
    Logger.log(LOG_MESSAGES.SCANNING_ROWS(productRows.length))

    productRows.forEach((row, index) => {
      // テンプレート行はスキップ
      if (row.outerHTML.includes(TEMPLATE_MARKER.NEW_RECORD)) {
        Logger.log(LOG_MESSAGES.ROW_SKIPPED_TEMPLATE(index))
        return
      }

      // 削除済み行はスキップ
      const destroyInput = row.querySelector(SELECTOR.DESTROY_INPUT)
      if (destroyInput && destroyInput.value === DESTROY_FLAG.TRUE) {
        Logger.log(LOG_MESSAGES.ROW_SKIPPED_DESTRUCTION(index))
        return
      }

      // 非表示行はスキップ
      if (row.style.display === DISPLAY_STYLE.NONE) {
        Logger.log(LOG_MESSAGES.ROW_SKIPPED_HIDDEN(index))
        return
      }

      const childController = this.application.getControllerForElementAndIdentifier(
        row,
        CONTROLLER_IDENTIFIER.ROW
      )

      if (childController && typeof childController[METHOD_NAME.GET_CURRENT_VALUES] === 'function') {
        const values = childController[METHOD_NAME.GET_CURRENT_VALUES]()

        Logger.log(
          LOG_MESSAGES.ROW_VALUES(index, values.quantity, values.price, values.subtotal, values.categoryId)
        )

        // 小計が0より大きい場合のみ集計
        if (values.subtotal > DEFAULT_VALUE.ZERO) {
          grandTotal += values.subtotal
          rowCount++

          // カテゴリ別集計（カテゴリIDが有効な場合）
          if (values.categoryId && values.categoryId !== DEFAULT_VALUE.ZERO) {
            if (!categoryTotals[values.categoryId]) {
              categoryTotals[values.categoryId] = DEFAULT_VALUE.ZERO
            }
            categoryTotals[values.categoryId] += values.subtotal
          }
        }
      } else {
        Logger.warn(LOG_MESSAGES.ROW_CONTROLLER_NOT_FOUND(index))
      }
    })

    Logger.log(LOG_MESSAGES.GRAND_TOTAL(CurrencyFormatter.format(grandTotal), rowCount))
    Logger.log(LOG_MESSAGES.CATEGORY_TOTALS, categoryTotals)

    this.updateDisplay(grandTotal, categoryTotals)

    Logger.log(LOG_MESSAGES.UPDATE_COMPLETE)

    // フラグを解除
    this.isUpdatingTotals = false
  }

  // 表示を更新
  // 総合計金額とカテゴリ別合計金額を表示要素に反映する
  updateDisplay(grandTotal, categoryTotals) {
    // 総合計の更新
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = CurrencyFormatter.format(grandTotal)
      Logger.log(LOG_MESSAGES.GRAND_TOTAL_UPDATED(CurrencyFormatter.format(grandTotal)))
    } else {
      Logger.warn(LOG_MESSAGES.GRAND_TOTAL_TARGET_NOT_FOUND)
    }

    // カテゴリ別合計の更新
    if (this.hasCategoryTotalTarget) {
      this.categoryTotalTargets.forEach(target => {
        const categoryId = target.dataset[DATA_ATTRIBUTE.CATEGORY_ID]
        const total = categoryTotals[categoryId] || DEFAULT_VALUE.ZERO
        target.textContent = CurrencyFormatter.format(total)
        Logger.log(LOG_MESSAGES.CATEGORY_TOTAL_UPDATED(categoryId, CurrencyFormatter.format(total)))
      })
    }
  }
}
