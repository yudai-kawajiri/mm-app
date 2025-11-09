/**
 * @file form/nested_form_item_controller.js
 * ネストフォームの子コントローラー - 行削除管理
 *
 * @module Controllers/Form
 */

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

/**
 * Nested Form Item Controller (Child)
 *
 * @description
 *   ネストフォームの子コントローラー。
 *   各行の削除ボタンを制御し、論理削除（_destroy フラグ）を行います。
 *
 * @example HTML での使用
 *   <tr data-controller="form--nested-form-item" data-unique-id="123">
 *     <td>
 *       <input
 *         type="hidden"
 *         name="plan[materials][123][_destroy]"
 *         value="0"
 *         data-form--nested-form-item-target="destroy"
 *       />
 *       <button data-action="click->form--nested-form-item#remove">削除</button>
 *     </td>
 *   </tr>
 *
 * @targets
 *   destroy - _destroy フラグのhidden input
 *
 * @features
 *   - 論理削除（_destroy = 1）
 *   - 複数タブの同期削除（同じunique-idを持つ行）
 *   - 合計再計算のトリガー（製造計画管理の場合）
 *
 * @requires utils/logger - ログ出力ユーティリティ
 */
export default class extends Controller {
  static targets = ["destroy"]

  /**
   * 遅延時間定数: 再計算処理の遅延（ミリ秒）
   *
   * 行削除後、DOM更新の完了を待ってから
   * 合計再計算を実行するための遅延時間。
   */
  static RECALCULATION_DELAY_MS = 100

  /**
   * 行を削除（論理削除）
   *
   * @param {Event} event - click イベント
   *
   * @description
   *   以下の処理を実行：
   *   1. _destroy フラグを "1" に設定
   *   2. 行を非表示
   *   3. 他のタブの同じunique-idを持つ行も削除
   *   4. 合計再計算をトリガー（製造計画管理の場合）
   */
  remove(event) {
    event.preventDefault()

    const row = this.element
    const uniqueId = row.dataset.uniqueId || row.dataset.rowUniqueId

    Logger.log(`Removing row: ${uniqueId}`)

    // _destroy フラグを立てる
    if (this.hasDestroyTarget) {
      this.destroyTarget.value = "1"
      Logger.log(`Set _destroy=1 for: ${this.destroyTarget.name}`)
    } else {
      Logger.error('Destroy target not found')
    }

    // この行を非表示
    row.style.display = "none"

    // 同じunique-idを持つ他のタブの行も削除
    if (uniqueId) {
      this.removeFromOtherTabs(uniqueId)
    }

    // 合計を再計算（製造計画管理の場合のみ）
    this.recalculateTotalsIfNeeded()

    Logger.log(`Row removed: ${uniqueId}`)
  }

  /**
   * 他のタブから同じ行を削除
   *
   * @param {string} uniqueId - ユニークID
   *
   * @description
   *   data-unique-id または data-row-unique-id が一致する
   *   すべての行を検索し、_destroy フラグを立てて非表示にします。
   */
  removeFromOtherTabs(uniqueId) {
    const selector = `tr[data-unique-id="${uniqueId}"], tr[data-row-unique-id="${uniqueId}"]`
    const allMatchingRows = document.querySelectorAll(selector)

    Logger.log(`Found ${allMatchingRows.length} matching rows with ID: ${uniqueId}`)

    allMatchingRows.forEach(row => {
      if (row !== this.element) {
        const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
        if (destroyInput) {
          destroyInput.value = "1"
          Logger.log(`Set _destroy=1 in other tab: ${destroyInput.name}`)
        }
        row.style.display = "none"
        Logger.log(`Hidden matching row in other tab`)
      }
    })
  }

  /**
   * 製造計画の合計を再計算（該当する場合のみ）
   *
   * @description
   *   resources--plan-product--totals コントローラーが存在する場合、
   *   合計再計算メソッドを呼び出します。
   */
  recalculateTotalsIfNeeded() {
    // 製造計画の totals コントローラーを探す
    const parentElement = document.querySelector('[data-controller~="resources--plan-product--totals"]')

    if (parentElement) {
      Logger.log('Recalculating totals after row removal')

      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        'resources--plan-product--totals'
      )

      if (parentController && typeof parentController.recalculate === 'function') {
        // 少し遅延させて DOM が更新された後に実行
        setTimeout(() => {
          parentController.recalculate({ type: 'row-removed' })
          Logger.log('Totals recalculated')
        }, this.constructor.RECALCULATION_DELAY_MS)
      } else {
        Logger.warn('Totals controller not found or invalid')
      }
    }
  }
}
