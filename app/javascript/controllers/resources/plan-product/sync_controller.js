/**
 * @file resources/plan-product/sync_controller.js
 * 製造計画のタブ間同期コントローラー
 *
 * @module Controllers/Resources/PlanProduct
 */

import { Controller } from "@hotwired/stimulus"
import Logger from "../../../utils/logger"

/**
 * Plan Product Sync Controller
 *
 * 製造計画：タブ間同期コントローラー。
 * 商品選択・数量入力を全タブに同期する。
 *
 * 責務:
 * - 商品選択の全タブ同期
 * - 数量入力の全タブ同期
 * - イベント発火による連鎖更新
 *
 * データフロー:
 * 1. ユーザーがAタブで商品を選択
 * 2. syncProductToOtherTabs() が発火
 * 3. 同じ row-unique-id を持つ全タブのセレクトボックスに同期
 * 4. 各セレクトボックスで change イベント発火
 * 5. row_controller が価格を取得・小計計算
 *
 * @extends Controller
 *
 * @example HTML での使用
 *   <tr data-controller="resources--plan-product--sync">
 *     <select
 *       data-row-unique-id="123"
 *       data-action="change->resources--plan-product--sync#syncProductToOtherTabs"
 *     >
 *       <option value="">選択</option>
 *     </select>
 *     <input
 *       type="number"
 *       data-row-unique-id="123"
 *       data-action="input->resources--plan-product--sync#syncQuantityToOtherTabs"
 *     />
 *   </tr>
 */
export default class extends Controller {
  // ============================================================
  // 商品選択の同期
  // ============================================================

  /**
   * 商品選択を他のタブに同期
   *
   * @param {Event} event - change イベント
   *
   * 同じ row-unique-id を持つ全てのセレクトボックスに
   * 選択された商品を同期する。
   */
  syncProductToOtherTabs(event) {
    const selectElement = event.currentTarget
    const selectedProductId = selectElement.value
    const uniqueRowId = selectElement.dataset.rowUniqueId

    Logger.log(`Sync product: ${selectedProductId} for row: ${uniqueRowId}`)

    const allMatchingSelects = document.querySelectorAll(`select[data-row-unique-id="${uniqueRowId}"]`)

    allMatchingSelects.forEach(select => {
      if (select !== selectElement && select.value !== selectedProductId) {
        select.value = selectedProductId

        // イベントを発火（ただし同期は防ぐ）
        const changeEvent = new Event('change', { bubbles: true })
        select.dispatchEvent(changeEvent)
      }
    })
  }

  // ============================================================
  // 数量入力の同期
  // ============================================================

  /**
   * 数量を他のタブに同期
   *
   * @param {Event} event - input イベント
   *
   * 同じ row-unique-id を持つ全ての数量入力フィールドに
   * 入力された数量を同期する。
   */
  syncQuantityToOtherTabs(event) {
    const inputElement = event.currentTarget
    const quantity = inputElement.value
    const uniqueRowId = inputElement.dataset.rowUniqueId

    Logger.log(`Sync quantity: ${quantity} for row: ${uniqueRowId}`)

    const allMatchingInputs = document.querySelectorAll(
      `input[data-resources--plan-product--row-target="productionCount"][data-row-unique-id="${uniqueRowId}"]`
    )

    allMatchingInputs.forEach(input => {
      if (input !== inputElement && input.value !== quantity) {
        input.value = quantity

        // イベントを発火（ただし同期は防ぐ）
        const inputEvent = new Event('input', { bubbles: true })
        input.dispatchEvent(inputEvent)
      }
    })
  }
}
